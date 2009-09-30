module icypixels.zoomable;

// phobos
import std.stdio;
import std.math;

// tango
version (Tango) {
    import tango.math.Math;
} else {
    int isNaN(real x)
    {
      alias floatTraits!(real) F;
      static if (real.mant_dig==53) { // double
            ulong*  p = cast(ulong *)&x;
            return (*p & 0x7FF0_0000_0000_0000 == 0x7FF0_0000_0000_0000) && *p & 0x000F_FFFF_FFFF_FFFF;
      } else static if (real.mant_dig==64) {     // real80
            ushort e = F.EXPMASK & (cast(ushort *)&x)[F.EXPPOS_SHORT];
            ulong*  ps = cast(ulong *)&x;
            return e == F.EXPMASK &&
                *ps & 0x7FFF_FFFF_FFFF_FFFF; // not infinity
      } else static if (real.mant_dig==113) {  // quadruple
            ushort e = F.EXPMASK & (cast(ushort *)&x)[F.EXPPOS_SHORT];
            ulong*  ps = cast(ulong *)&x;
            return e == F.EXPMASK &&
               (ps[MANTISSA_LSB] | (ps[MANTISSA_MSB]& 0x0000_FFFF_FFFF_FFFF))!=0;
      } else {
          return x!=x;
      }
    }
    
    /** Returns the minimum number of x and y, favouring numbers over NaNs.
     *
     * If both x and y are numbers, the minimum is returned.
     * If both parameters are NaN, either will be returned.
     * If one parameter is a NaN and the other is a number, the number is
     * returned (this behaviour is mandated by IEEE 754R, and is useful
     * for determining the range of a function).
     */
    real minNum(real x, real y) {
        if (x<=y || isNaN(y)) return x; else return y;
    }

    /** Returns the maximum number of x and y, favouring numbers over NaNs.
     *
     * If both x and y are numbers, the maximum is returned.
     * If both parameters are NaN, either will be returned.
     * If one parameter is a NaN and the other is a number, the number is
     * returned (this behaviour is mandated by IEEE 754-2008, and is useful
     * for determining the range of a function).
     */
    real maxNum(real x, real y) {
        if (x>=y || isNaN(y)) return x; else return y;
    }
}

// external modules
import derelict.opengl.gl;

// icy modules
import icypixels.vector;

class Zoomable {
	public Vector2D screenOffset;
	Vector2D screenSize;
	Vector2D worldSize;
	
	double zoomFactor = 1.0f;
	Vector2D worldPan;
	
	double worldStretch;
	
	double minZoom = double.nan; // default: no minimum
	double maxZoom = double.nan; // default: no maximum
	
	this( Vector2D screenSize, Vector2D worldSize ) {
		this.screenSize = screenSize;
		this.worldSize = worldSize;
		
		this.worldPan = Vector2D( 0.0f, 0.0f );
		
		// work out the multiplier to make zoom of 1.0 fit screen exactly
		Vector2D worldStretchV = screenSize / worldSize;
		
		this.screenOffset = Vector2D( 0.0f, 0.0f );
		
		worldStretch = minNum( worldStretchV.x, worldStretchV.y );
	}
	
	double realZoom( ) {
		return (zoomFactor * worldStretch);
	}
	
	T worldToScreen( T )( T v ) {
		return v * realZoom;
	}
	
	T screenToWorld( T )( T v ) {
		return v / realZoom;
	}
	
	Vector2D panToWorld( Vector2D worldPoint ) {
		return worldPoint - worldPan;
	}
	
	Vector2D unpanFromWorld( Vector2D worldPoint ) {
		return worldPoint + worldPan;
	}
	
	Vector2D screenToWorldPanned( Vector2D v ) {
		return panToWorld( screenToWorld( v ) );
	}
	
	Vector2D worldToScreenPanned( Vector2D v ) {
		return worldToScreen( unpanFromWorld( v ) );
	}
	
	void constrain( ) {
		// constrain zoom
		zoomFactor = maxNum( zoomFactor, minZoom );
		zoomFactor = minNum( zoomFactor, maxZoom );
		
		// panning constraint (must be before centering below)
		worldPan.x = minNum( worldPan.x, 0 );
		worldPan.y = minNum( worldPan.y, 0 );
		
		Vector2D maxPan = (worldSize - screenToWorld(screenSize)) * -1;
		worldPan.x = maxNum( worldPan.x, maxPan.x );
		worldPan.y = maxNum( worldPan.y, maxPan.y );
		
		// check if we need centering (when world smaller than screen)
		Vector2D worldInScreen = worldToScreen( worldSize );
		
		if ( worldInScreen.x < screenSize.x ) {
			worldPan.x = screenToWorld( (screenSize.x - worldInScreen.x) / 2 ) + screenOffset.x;
		}
		
		if ( worldInScreen.y < screenSize.y ) {
			worldPan.y = screenToWorld( (screenSize.y - worldInScreen.y) / 2 ) + screenOffset.y;
		}
	}
	
	void glTransform( ) {
		constrain( );
		
		glScalef( realZoom, realZoom, 1 );
		Vector2D translation;
		translation = screenOffset + worldPan;
		glTranslatef( translation.x, translation.y, 0 );
	}
	
	// pans the world so worldPoint is positioned under screenPoint
	void panWorldToScreen( Vector2D worldPoint, Vector2D screenPoint ) {
		Vector2D tmpPan = worldPoint * -1;
		
		// now we have the world point at 0,0 on the screen
		// adjust the pan to screenPoint instead
		tmpPan = tmpPan + screenToWorld(screenPoint);
		
		worldPan = tmpPan;
	}
	
	
	
	void zoomDelta( double delta ) {
		zoomFactor += delta;
	}
	
	void panDelta( Vector2D delta ) {
		worldPan += delta;
	}
	
	void setClosestZoom( double closestZoom ) {
		minZoom = closestZoom;
	}
	
	// zooms the world, making sure the world point under zoomScreenPoint remains under zoomScreenPoint
	void zoomDeltaCentered( double delta, Vector2D zoomScreenPoint ) {
		constrain( ); // make sure we're constrained before calculating
		
		// get the absolute world point under zoomPoint
		Vector2D centerPoint = panToWorld( screenToWorld( zoomScreenPoint ) );
		
		// do the actual zooming
		zoomDelta( delta );
		
		// reset the panning
		panWorldToScreen( centerPoint, zoomScreenPoint );
	}
}
