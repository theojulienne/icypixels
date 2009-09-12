module icypixels.texture;

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

import std.stdio;

import tango.io.Stdout;

import icypixels.util;
import icypixels.loadable;

abstract class Texture : Loadable
{
	GLuint[] texture;
	bool created[];
	
	float w, h;
	
	float width( )
	{
		return w;
	}
	
	float height( )
	{
		return h;
	}
	
	abstract void activateAll( );
	abstract void deactivateAll( );
	
	void genTextures( int num )
	{
		texture.length = num;
		created.length = num;
		
		for ( int a = 0; a < num; a++ )
		{
			created[a] = false;
		}
		
		glGenTextures( num, texture.ptr );
	}
	
	void updateData( uint channel, GLint internalformat, GLenum format, GLenum type, int width, int height, void *data, int stride=-1, GLuint tex_id=GL_TEXTURE0 )
	{
		if ( stride == -1 )
		{
			stride = width * 3;
		}
		
		this.activate( tex_id, channel );
		
		/*glTexParameteri( GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
		glTexParameteri( GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
		glTexEnvf( GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_DECAL );*/
		glTexParameteri( GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
		glTexParameteri( GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
		glTexParameteri( GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_S, GL_CLAMP );
		glTexParameteri( GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_T, GL_CLAMP );
		glTexEnvf( GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE );
		
		//writefln( "updateData %s (%s,%s,%s) (%s,%s), %s", channel, internalformat, format, type, width, height, stride );

		glPixelStorei( GL_UNPACK_ROW_LENGTH, stride );

		if ( !created[channel] )
		{
			glTexImage2D( GL_TEXTURE_RECTANGLE_ARB, 0, internalformat, width, height, 0, format, type, data );
			w = width;
			h = height;
			created[channel] = true;
		}
		else
			glTexSubImage2D( GL_TEXTURE_RECTANGLE_ARB, 0, 0, 0, width, height, format, type, data );
		
		this.deactivate( tex_id );
		
		checkGLErrors( "updateData" );
	}
	
	void updateData( uint channel, GLint internalformat, GLenum format, GLenum type, void *data, int stride, GLuint tex_id=GL_TEXTURE0 )
	{
		this.updateData( channel, internalformat, format, type, cast(int)w, cast(int)h, data, stride, tex_id );
	}
	
	abstract void activate( GLuint tex_id=GL_TEXTURE0, uint num=0 );
	abstract void deactivate( GLuint tex_id=GL_TEXTURE0 );
	
	void texCoordTopLeft( )
	{
		glTexCoord2f( 0, 0 );
	}
	
	void texCoordTopRight( )
	{
		glTexCoord2f( this.width, 0 );
	}
	
	void texCoordBottomLeft( )
	{
		glTexCoord2f( 0, this.height );
	}
	
	void texCoordBottomRight( )
	{
		glTexCoord2f( this.width, this.height );
	}
}

/*
GLuint load_texture( char[] file, float *w, float *h )
{
	SDL_Surface* surface = IMG_Load(std.string.toStringz(file));
	if(surface is null) {
		throw new Exception( "Failed to load image from file (" ~ file ~ ")." );
	}

	GLuint texture;
	glGenTextures( 1, &texture);
	glBindTexture( GL_TEXTURE_RECTANGLE_ARB, texture);
	glPixelStorei( GL_UNPACK_ALIGNMENT, 4);
	glTexParameteri( GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
	glTexParameteri( GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
	glTexParameteri( GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_S, GL_CLAMP );
	glTexParameteri( GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_T, GL_CLAMP );
	glTexEnvf( GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE ); //GL_DECAL
	
	SDL_PixelFormat *format = surface.format;
	
	*w = surface.w;
	*h = surface.h;
	
	if (format.Amask)
		glTexImage2D( GL_TEXTURE_RECTANGLE_ARB, 0, GL_RGBA, surface.w, surface.h, 0, GL_RGBA, GL_UNSIGNED_BYTE, surface.pixels );
	else
		glTexImage2D( GL_TEXTURE_RECTANGLE_ARB, 0, GL_RGB, surface.w, surface.h, 0, GL_RGB, GL_UNSIGNED_BYTE, surface.pixels );
	
	checkGLErrors( "icygl.texture.load_texture" );
	SDL_FreeSurface(surface);
	
	return texture;
}
*/
class ImageTexture: Texture
{
	string filename = null;
	
	this( char[] file )
	{
		this.filename = file;
		w = 1;
		h = 1;
	}
	
	this( uint numChannels=1 )
	{
		if ( numChannels > 0 )
		{
			genTextures( numChannels );
		}
		
		loadState = LoadState.Loaded;
	}
	
	SDL_Surface *surface = null;
	
	void load( ) {
		if ( filename !is null ) {
			surface = IMG_Load(std.string.toStringz(filename));
			
			if ( surface is null ) {
				throw new Exception( "Failed to load image from file (" ~ filename ~ ")." );
			}
			
			w = surface.w;
			h = surface.h;
			
			pipeToGL( );
			
			/*texture.length = 1;
			texture[0] = load_texture( filename, &w, &h );*/
		}
	}
	
	void activateAll( ) { activate; }
	void deactivateAll( ) { deactivate; }
	
	void pipeToGL( ) {
		GLuint tex;
		glGenTextures( 1, &tex);
		glBindTexture( GL_TEXTURE_RECTANGLE_ARB, tex);
		glPixelStorei( GL_UNPACK_ALIGNMENT, 4);
		glTexParameteri( GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
		glTexParameteri( GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
		glTexParameteri( GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_S, GL_CLAMP );
		glTexParameteri( GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_T, GL_CLAMP );
		glTexEnvf( GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE ); //GL_DECAL

		SDL_PixelFormat *format = surface.format;

		if (format.Amask)
			glTexImage2D( GL_TEXTURE_RECTANGLE_ARB, 0, GL_RGBA, surface.w, surface.h, 0, GL_RGBA, GL_UNSIGNED_BYTE, surface.pixels );
		else
			glTexImage2D( GL_TEXTURE_RECTANGLE_ARB, 0, GL_RGB, surface.w, surface.h, 0, GL_RGB, GL_UNSIGNED_BYTE, surface.pixels );

		checkGLErrors( "icygl.texture.load_texture" );
		SDL_FreeSurface(surface);
		surface = null;
		
		Stdout.format( "texture '{0}' has been piped to GL", filename ).newline;
		
		texture.length = 1;
		texture[0] = tex;
	}
	
	void activate( GLuint tex_id=GL_TEXTURE0, uint num=0 )
	{
		GLuint tex = 0;
		
		// only active texture if it has been loaded
		if ( loadState == LoadState.Loaded ) {
			// check if loaded but not piped to GL yet
			if ( surface !is null )
				pipeToGL( );
			
			tex = texture[num];
		}
		
		version (Windows) {} else glActiveTexture( tex_id );
		glBindTexture( GL_TEXTURE_RECTANGLE_ARB, tex );
	}
	
	void deactivate( GLuint tex_id=GL_TEXTURE0 )
	{
		version (Windows) {} else glActiveTexture( tex_id );
		glBindTexture( GL_TEXTURE_RECTANGLE_ARB, 0 );
	}
}

class YUVDataTexture: Texture
{
	this( float _w, float _h )
	{
		w = _w;
		h = _h;
	}
	
	this( )
	{
		genTextures( 3 );
	}
	
	void activateAll( ) { YUVactivate; }
	void deactivateAll( ) { YUVdeactivate; }
	
	void YUVactivate( )
	{
		activate( GL_TEXTURE0, 0 );
		activate( GL_TEXTURE1, 1 );
		activate( GL_TEXTURE2, 2 );
	}
	
	void YUVdeactivate( )
	{
		deactivate( GL_TEXTURE0 );
		deactivate( GL_TEXTURE1 );
		deactivate( GL_TEXTURE2 );
	}
	
	void activate( GLuint tex_id=GL_TEXTURE0, uint num=0 )
	{
		version (Windows) {} else glActiveTexture( tex_id );
		glBindTexture( GL_TEXTURE_RECTANGLE_ARB, texture[num] );
	}
	
	void deactivate( GLuint tex_id=GL_TEXTURE0 )
	{
		version (Windows) {} else glActiveTexture( tex_id );
		glBindTexture( GL_TEXTURE_RECTANGLE_ARB, 0 );
	}
	
	void updateYUV420PData( int width, int height, ubyte** data, int[] stride )
	{
		updateData( 0, GL_LUMINANCE, GL_LUMINANCE, GL_UNSIGNED_BYTE, width, height, data[0], stride[0], GL_TEXTURE0 );
		updateData( 1, GL_LUMINANCE, GL_LUMINANCE, GL_UNSIGNED_BYTE, width>>1, height>>1, data[1], stride[1], GL_TEXTURE1 );
		updateData( 2, GL_LUMINANCE, GL_LUMINANCE, GL_UNSIGNED_BYTE, width>>1, height>>1, data[2], stride[2], GL_TEXTURE2 );
	}
}