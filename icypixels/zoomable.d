module icypixels.zoomable;

// phobos
import std.stdio;
import std.math;

// tango
import tango.math.Math;

// external modules
import derelict.opengl.gl;

// icy modules
import icypixels.vector;

class Zoomable {
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
		
		worldStretch = minNum( worldStretchV.x, worldStretchV.y );
	}
	
	private double realZoom( ) {
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
			worldPan.x = screenToWorld( (screenSize.x - worldInScreen.x) / 2 );
		}
		
		if ( worldInScreen.y < screenSize.y ) {
			worldPan.y = screenToWorld( (screenSize.y - worldInScreen.y) / 2 );
		}
	}
	
	void glTransform( ) {
		constrain( );
		
		glScalef( realZoom, realZoom, 1 );
		glTranslatef( worldPan.x, worldPan.y, 0 );
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
