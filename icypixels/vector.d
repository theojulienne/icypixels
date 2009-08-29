module icypixels.vector;

import derelict.opengl.gl;

import std.compat;
import std.math;
import std.string;

struct Vector( int DIMS ) {
	//float x=0, y=0, z=0;
	float[DIMS] values;
	
	float x( ) {
		return values[0];
	}
	
	float y( ) {
		return values[1];
	}
	
	float z( ) {
		static if ( DIMS >= 3 ) {
			return values[2];
		} else {
			return 0;
		}
	}
	
	void x( float x ) {
		values[0] = x;
	}
	
	void y( float y ) {
		values[1] = y;
	}
	
	void z( float z ) {
		static if ( DIMS >= 3 ) {
			values[2] = z;
		}
	}
	
	
	
	static Vector opCall( float values[] ... ) {
		Vector v;
		v.values[0..$] = values;
		return v;
	}

	Vector opAssign( float[] nd ) {
		this.values[0..$] = nd;
		return *this;
	}
		
	void set( float values[] ... ) {
		this.values[0..$] = values;
	}
	
	void normalize( ) {
		float len;
		
		float max = 0;
		
		foreach ( value; values ) {
			max += (value*value);
		}
		
		len = cast(float)sqrt( max );

		if(len == 0.0f)						// Prevents Divide By 0 Error By Providing
			len = 1.0f;						// An Acceptable Value For Vectors To Close To 0.
		
		for ( int i = 0; i < values.length; i++ ) {
			values[i] /= len;
		}
	}
	
	void zero( ) {
		for ( int i = 0; i < values.length; i++ ) {
			values[i] = 0;
		}
	}
	
	int opAddAssign( Vector n ) {
		for ( int i = 0; i < values.length; i++ ) {
			values[i] += n.values[i];
		}
		
		return 0;
	}
	
	int opSubAssign( Vector n ) {
		for ( int i = 0; i < values.length; i++ ) {
			values[i] -= n.values[i];
		}
		
		return 0;
	}
	
	int opDivAssign( float n ) {
		for ( int i = 0; i < values.length; i++ ) {
			values[i] /= n;
		}
		
		return 0;
	}
	
	int opMulAssign( float n ) {
		for ( int i = 0; i < values.length; i++ ) {
			values[i] *= n;
		}
		
		return 0;
	}
	
	Vector cross( Vector on ) {
		Vector n;
		
		assert( values.length == 3 );
		
		n.x = y*on.z - z*on.y;				// Cross Product For Y - Z
		n.y = z*on.x - x*on.z;				// Cross Product For X - Z
		n.z = x*on.y - y*on.x;				// Cross Product For X - Y
		
		return n;
	}
	
	float dot( Vector v2 ) {
		float d = 0;
		
		for ( int i = 0; i < values.length; i++ ) {
			d += values[i] * v2.values[i];
		}
		
		return d;
	}
	
	
	Vector opAdd( Vector v ) {
		Vector tv = *this;
		tv += v;
		return tv;
	}
	
	Vector opSub( Vector v ) {
		Vector tv = *this;
		tv -= v;
		return tv;
	}
	
	Vector opMul( float n ) {
		Vector tv = *this;
		tv *= n;
		return tv;
	}
	
	Vector opDiv( float n ) {
		Vector tv = *this;
		tv /= n;
		return tv;
	}
	
	Vector opDiv( Vector n ) {
		Vector tv = *this;
		for ( int i = 0; i < values.length; i++ ) {
			tv.values[i] = values[i] / n.values[i];
		}
		return tv;
	}
	
	int opEquals( Vector v ) {
		for ( int i = 0; i < values.length; i++ ) {
			if ( v.values[i] != values[i] ) {
				return false;
			}
		}
		
		return true;
	}
	
	static Vector getAverage( Vector vs[] ... ) {
		Vector tmp;
		
		foreach ( v; vs )
			tmp += v;
		
		tmp /= vs.length;
		
		return tmp;
	}
	
	void glv() {
		glVertex3f( x, y, z );
	}
	
	float distance( Vector!(DIMS) from ) {
		float sumSquares = 0;
		
		for ( int i = 0; i < values.length; i++ ) {
			float diff = values[i] - from.values[i];
			sumSquares += (diff*diff);
		}
		
		return sqrt( sumSquares );
	}
	
	string toString( ) {
		return "<Vector>";
	}
}

alias Vector!(2) Vector2D;
alias Vector!(3) Vector3D;