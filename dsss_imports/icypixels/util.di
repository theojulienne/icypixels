module icypixels.util;

import derelict.sdl.sdl;
import derelict.sdl.image;
import derelict.opengl.gl;
import derelict.opengl.glu;
import derelict.opengl.extension.arb.texture_rectangle;

import std.stdio;
import std.string;

class GLException : Exception {
	this( GLenum errno, string where ) {
		string err = std.string.toString( cast(char *)gluErrorString(errno) );
		string trail = "";
		if ( where != "" ) {
			trail = format( " [%s]", where );
		}
		
		super( format( "%s (%s)", err, errno ) ~ trail );
	}
}

void clearGLErrors( ) {
	GLenum err = glGetError();
	while (err != GL_NO_ERROR) {
		glGetError();
	}
}

void checkGLErrors( char where[]="" ) {
	GLenum err = glGetError();
	while (err != GL_NO_ERROR) {
		throw new GLException( err, where );
		err = glGetError();
	}
}


class SDLException : Exception {
	this( string humanReadable ) {
		string err = std.string.toString( SDL_GetError( ) );
		super( humanReadable ~ ": " ~ err );
	}
}


version (build) {
    debug {
        pragma(link, "icypixels");
    } else {
        pragma(link, "icypixels");
    }
}
