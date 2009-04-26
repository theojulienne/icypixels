module example;

import derelict.opengl.gl;

import std.stdio;

import icypixels.all;
import icypixels.xml;

void handleKeyUp( GLWindow window, Event event ) {
	KeyUpEvent keyEvent = cast(KeyUpEvent)event;
	
	if ( keyEvent.keyCode == KeyCode.Escape ) {
		window.endLoop( );
	}
}

Texture tex;
Model em;

void handleRedraw( GLWindow window, Event event ) {
	glLoadIdentity( );
	
	glRotatef( 15.0f, 1.0f, 0.0f, 0.0f );
	glTranslatef( 0.0f, -4.8f, -8.0f );
	
	static float a = 0.0f;
	glRotatef( a, 0.0f, 1.0f, 0.0f );
	a += 0.03f;
	
	glColor4f( 1, 1, 1, 1 );
	//Primitives.renderBox( 1, 1, 1, tex );
	
	glPushMatrix( );
	glRotatef( 90.0f, -1.0f, 0.0f, 0.0f );
	glScalef( 0.0005f, 0.0005f, 0.0005f );
	em.render( );
	glPopMatrix( );
}

int main( string[] args ) {
	GLWindow win = new GLWindow( 800, 600 );
	win.title = "IcyPixels Example";
	
	//em = ColladaModel.loadDAE( "EiffelTower/models/EiffelTower.dae" );
	em = ColladaModel.loadDAE( "bram/models/bram.dae" );
	
	win.onKeyUpEvent += &handleKeyUp;
	win.onRedraw += &handleRedraw;
	
	tex = new ImageTexture( "uptex.jpg" );
	
	win.runLoop( );
	
	return 0;
}
