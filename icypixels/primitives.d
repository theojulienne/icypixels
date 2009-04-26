module icypixels.primitives;

import derelict.opengl.gl;

import icypixels.texture;

class Primitives {
	static void renderSprite( float width=1.0f, float height=1.0f, Texture tex=null ) {
		tex.activate();
		glBegin(GL_QUADS);
			if ( tex !is null ) tex.texCoordBottomRight;
		    glVertex2f( width, height );	// Top Right Of The Quad
			if ( tex !is null ) tex.texCoordBottomLeft;
		    glVertex2f( 0.0f, height );	// Top Left Of The Quad
			if ( tex !is null ) tex.texCoordTopLeft;
		    glVertex2f( 0.0f, 0.0f );	// Bottom Left Of The Quad
			if ( tex !is null ) tex.texCoordTopRight;
		    glVertex2f( width, 0.0f );	// Bottom Right Of The Quad
		glEnd();
		tex.deactivate();
	}
	
	static void renderGroundPlane( float width=1.0f, float height=1.0f, Texture tex=null ) {
		// halve the dimensions so it's the distance from 0,0,0 to each vertex
		width /= 2.0f;
		height /= 2.0f;
		
		tex.activate();
		glBegin(GL_QUADS);
			if ( tex !is null ) tex.texCoordBottomRight;
		    glVertex3f( width, 0.0f, height);	// Top Right Of The Quad
			if ( tex !is null ) tex.texCoordBottomLeft;
		    glVertex3f(-width, 0.0f, height);	// Top Left Of The Quad
			if ( tex !is null ) tex.texCoordTopLeft;
		    glVertex3f(-width, 0.0f, -height);	// Bottom Left Of The Quad
			if ( tex !is null ) tex.texCoordTopRight;
		    glVertex3f( width, 0.0f, -height);	// Bottom Right Of The Quad
		glEnd();
		tex.deactivate();
	}

	static void renderBox( float width=1.0f, float height=1.0f, float depth=1.0f, Texture tex=null ) {
		// halve the dimensions so it's the distance from 0,0,0 to each vertex
		width /= 2.0f;
		height /= 2.0f;
		depth /= 2.0f;
		
		
		tex.activate();
		glBegin(GL_QUADS);		// Draw The Cube Using quads
			if ( tex !is null ) tex.texCoordTopRight;
		    glVertex3f( width, height,-depth);	// Top Right Of The Quad (Top)
			if ( tex !is null ) tex.texCoordTopLeft;
		    glVertex3f(-width, height,-depth);	// Top Left Of The Quad (Top)
			if ( tex !is null ) tex.texCoordBottomLeft;
		    glVertex3f(-width, height, depth);	// Bottom Left Of The Quad (Top)
			if ( tex !is null ) tex.texCoordBottomRight;
		    glVertex3f( width, height, depth);	// Bottom Right Of The Quad (Top)

			if ( tex !is null ) tex.texCoordTopRight;
		    glVertex3f( width,-height, depth);	// Top Right Of The Quad (Bottom)
			if ( tex !is null ) tex.texCoordTopLeft;
		    glVertex3f(-width,-height, depth);	// Top Left Of The Quad (Bottom)
			if ( tex !is null ) tex.texCoordBottomLeft;
		    glVertex3f(-width,-height,-depth);	// Bottom Left Of The Quad (Bottom)
			if ( tex !is null ) tex.texCoordBottomRight;
		    glVertex3f( width,-height,-depth);	// Bottom Right Of The Quad (Bottom)

			if ( tex !is null ) tex.texCoordTopRight;
		    glVertex3f( width, height, depth);	// Top Right Of The Quad (Front)
			if ( tex !is null ) tex.texCoordTopLeft;
		    glVertex3f(-width, height, depth);	// Top Left Of The Quad (Front)
			if ( tex !is null ) tex.texCoordBottomLeft;
		    glVertex3f(-width,-height, depth);	// Bottom Left Of The Quad (Front)
			if ( tex !is null ) tex.texCoordBottomRight;
		    glVertex3f( width,-height, depth);	// Bottom Right Of The Quad (Front)

			if ( tex !is null ) tex.texCoordTopRight;
		    glVertex3f(-width, height,-depth);	// Top Right Of The Quad (Back)
			if ( tex !is null ) tex.texCoordTopLeft;
		    glVertex3f( width, height,-depth);	// Top Left Of The Quad (Back)
			if ( tex !is null ) tex.texCoordBottomLeft;
		    glVertex3f( width,-height,-depth);	// Bottom Left Of The Quad (Back)
			if ( tex !is null ) tex.texCoordBottomRight;
		    glVertex3f(-width,-height,-depth);	// Bottom Right Of The Quad (Back)

			if ( tex !is null ) tex.texCoordTopRight;
		    glVertex3f(-width, height, depth);	// Top Right Of The Quad (Left)
			if ( tex !is null ) tex.texCoordTopLeft;
		    glVertex3f(-width, height,-depth);	// Top Left Of The Quad (Left)
			if ( tex !is null ) tex.texCoordBottomLeft;
		    glVertex3f(-width,-height,-depth);	// Bottom Left Of The Quad (Left)
			if ( tex !is null ) tex.texCoordBottomRight;
		    glVertex3f(-width,-height, depth);	// Bottom Right Of The Quad (Left)

			if ( tex !is null ) tex.texCoordTopRight;
		    glVertex3f( width, height,-depth);	// Top Right Of The Quad (Right)
			if ( tex !is null ) tex.texCoordTopLeft;
		    glVertex3f( width, height, depth);	// Top Left Of The Quad (Right)
			if ( tex !is null ) tex.texCoordBottomLeft;
		    glVertex3f( width,-height, depth);	// Bottom Left Of The Quad (Right)
			if ( tex !is null ) tex.texCoordBottomRight;
		    glVertex3f( width,-height,-depth);	// Bottom Right Of The Quad (Right)
		glEnd();			// End Drawing The Cube
		tex.deactivate();
	}
}