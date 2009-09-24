module icypixels.util;

version (darwin) {
	import derelict.sdl.sdl;
	import derelict.sdl.image;
	import derelict.opengl.gl;
	import derelict.opengl.glu;
	import derelict.opengl.extension.arb.texture_rectangle;
} else {
	import icylict.opengl;
	import icylict.openglu;
	import icylict.SDL.SDL;
}

import std.compat;
import std.stdio;
import std.string;

import tango.stdc.stringz;

class GLException : Exception {
	this( GLenum errno, string where ) {
		string err = fromStringz( cast(char *)gluErrorString(errno) );
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

import tango.io.Stdout;
import tango.stdc.stringz;
import tango.text.Util;

bool glHaveExtension( string extension ) {
	string extensions = null;
	
	extensions = fromStringz( const(char*)glGetString( GL_EXTENSIONS ) );
	
	string[] extList = extensions.split( " " );
	
	foreach ( ext; extList ) {
		if ( ext == extension ) {
			return true;
		}
	}
	
	return false;
}
/+
isExtensionSupported(const char *extension)
{
  const GLubyte *extensions = NULL;
  const GLubyte *start;
  GLubyte *where, *terminator;
  /* Extension names should not have spaces. */
  where = (GLubyte *) strchr(extension, ' ');
  if (where || *extension == '\0')
    return 0;
  extensions = glGetString(GL_EXTENSIONS);
  /* It takes a bit of care to be fool-proof about parsing the
     OpenGL extensions string. Don't be fooled by sub-strings,
     etc. */
  start = extensions;
  for (;;) {
    where = (GLubyte *) strstr((const char *) start, extension);
    if (!where)
      break;
    terminator = where + strlen(extension);
    if (where == start || *(where - 1) == ' ')
      if (*terminator == ' ' || *terminator == '\0')
        return 1;
    start = terminator;
  }
  return 0;
}
+/

