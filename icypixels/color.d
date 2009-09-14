module icypixels.color;

version (darwin) {
	import derelict.sdl.sdl;
	import derelict.sdl.image;
	import derelict.opengl.gl;
	import derelict.opengl.extension.arb.texture_rectangle;
} else {
	import icylict.opengl;
	import icylict.openglu;
	import icylict.gl_arb;
	import icylict.SDL.SDL;
	import icylict.SDL.SDL_Image;
}

struct Color
{
	double r, g, b, a;
	
	static Color create( float r, float g, float b, float a )
	{
		Color c;
		c.r = r;
		c.g = g;
		c.b = b;
		c.a = a;
		return c;
	}
	
	static Color create( float r, float g, float b )
	{
		return Color.create( r, g, b, 1 );
	}
	
	void setGL( ) {
		glColor4f( r, g, b, a );
	}
}
