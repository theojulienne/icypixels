module icypixels.window;

version (darwin) {
	import derelict.sdl.sdl;
	import derelict.sdl.image;
	import derelict.opengl.gl;
	import derelict.opengl.extension.arb.texture_rectangle;
} else {
	import icylict.opengl;
	import icylict.openglu;
	import icylict.SDL.SDL;
	import icylict.gl_arb;
}

import std.compat;
import std.string;

import icypixels.util;

void loadIcyPixelsDeps()
{
	version (darwin) {
		DerelictSDL.load();
		DerelictSDLImage.load();
		DerelictGL.load();
		DerelictGLU.load();
	}
}

class Event {
	
}

enum KeyCode {
	Backspace = SDLK_BACKSPACE,
	Tab = SDLK_TAB,
	Clear = SDLK_CLEAR,
	Return = SDLK_RETURN,
	Pause = SDLK_PAUSE,
	Escape = SDLK_ESCAPE,
	Space = SDLK_SPACE,
	Exclaim = SDLK_EXCLAIM,
	QuoteDbl = SDLK_QUOTEDBL,
	Hash = SDLK_HASH,
	Dollar = SDLK_DOLLAR,
	Ampersand = SDLK_AMPERSAND,
	Quote = SDLK_QUOTE,
	LeftParen = SDLK_LEFTPAREN,
	RightParen = SDLK_RIGHTPAREN,
	Asterisk = SDLK_ASTERISK,
	Plus = SDLK_PLUS,
	Comma = SDLK_COMMA,
	Minus = SDLK_MINUS,
	Period = SDLK_PERIOD,
	Slash = SDLK_SLASH,
	
	Colon = SDLK_COLON,
	Semicolon = SDLK_SEMICOLON,
	Less = SDLK_LESS,
	Equals = SDLK_EQUALS,
	Greater = SDLK_GREATER,
	Question = SDLK_QUESTION,
	At = SDLK_AT,
	
	LeftBracket = SDLK_LEFTBRACKET,
	Backslash = SDLK_BACKSLASH,
	RightBracket = SDLK_RIGHTBRACKET,
	Caret = SDLK_CARET,
	Underscore = SDLK_UNDERSCORE,
	Backquote = SDLK_BACKQUOTE,
	
	A = SDLK_a,
	B = SDLK_b,
	C = SDLK_c,
	D = SDLK_d,
	E = SDLK_e,
	F = SDLK_f,
	G = SDLK_g,
	H = SDLK_h,
	I = SDLK_i,
	J = SDLK_j,
	K = SDLK_k,
	L = SDLK_l,
	M = SDLK_m,
	N = SDLK_n,
	O = SDLK_o,
	P = SDLK_p,
	Q = SDLK_q,
	R = SDLK_r,
	S = SDLK_s,
	T = SDLK_t,
	U = SDLK_u,
	V = SDLK_v,
	W = SDLK_w,
	X = SDLK_x,
	Y = SDLK_y,
	Z = SDLK_z,
	
	Delete = SDLK_DELETE,
	
	/* Arrows + Home/End pad */
	Up = SDLK_UP,
	Down = SDLK_DOWN,
	Left = SDLK_LEFT,
	Right = SDLK_RIGHT,
	Insert = SDLK_INSERT,
	Home = SDLK_HOME,
	End = SDLK_END,
	PageUp = SDLK_PAGEUP,
	PageDown = SDLK_PAGEDOWN,
	
	/* Function Keys */
	F1 = SDLK_F1,
	F2 = SDLK_F2,
	F3 = SDLK_F3,
	F4 = SDLK_F4,
	F5 = SDLK_F5,
	F6 = SDLK_F6,
	F7 = SDLK_F7,
	F8 = SDLK_F8,
	F9 = SDLK_F9,
	F10 = SDLK_F10,
	F11 = SDLK_F11,
	F12 = SDLK_F12,
	F13 = SDLK_F13,
	F14 = SDLK_F14,
	F15 = SDLK_F15,
	
	/* FIXME: Key state modifiers */
	/* FIXME: Misc. function keys */
}

enum MouseButton {
	Primary=1,
	Middle=2,
	Secondary=3,
	
	WheelUp=4,
	WheelDown=5,
}

class KeyEvent : Event {
	SDL_Event event;
	
	this( SDL_Event e ) {
		event = e;
	}
	
	KeyCode keyCode( ) {
		return cast(KeyCode) event.key.keysym.sym;
	}
}

class KeyUpEvent : KeyEvent {
	this( SDL_Event e ) {
		super( e );
	}
}

class KeyDownEvent : KeyEvent {
	this( SDL_Event e ) {
		super( e );
	}
}

class MouseEvent : Event {
	SDL_Event event;
	
	this( SDL_Event e ) {
		event = e;
	}
	
	float mouseX( ) {
		return event.motion.x;
	}
	
	float mouseY( ) {
		return event.motion.y;
	}
	
	MouseButton button( ) {
		return cast(MouseButton)event.button.button;
	}
}

class MouseMoveEvent : MouseEvent {
	this( SDL_Event e ) {
		super( e );
	}
}

class MouseUpEvent : MouseEvent {
	this( SDL_Event e ) {
		super( e );
	}
}

class MouseDownEvent : MouseEvent {
	this( SDL_Event e ) {
		super( e );
	}
}

alias void delegate( GLWindow window, Event event ) EventHandlerDelegate;
alias void function( GLWindow window, Event event ) EventHandlerFunction;

// a mixed delegate+function type for event handlers
struct EventHandler {
	private EventHandlerDelegate del;
	private EventHandlerFunction fun;
	
	static EventHandler opCall( EventHandlerDelegate del ) {
		EventHandler eh;
		eh.del = del;
		return eh;
	}
	
	static EventHandler opCall( EventHandlerFunction fun ) {
		EventHandler eh;
		eh.fun = fun;
		return eh;
	}
	
	void opCall( GLWindow window, Event event ) {
		if ( this.del !is null )
			this.del( window, event );
		
		if ( this.fun !is null )
			this.fun( window, event );
	}
}

struct EventAttribute {
	EventHandler[] handlers;
	
	void opAddAssign( EventHandlerDelegate del ) {
		addHandler( EventHandler( del ) );
	}
	
	void opAddAssign( EventHandlerFunction fun ) {
		addHandler( EventHandler( fun ) );
	}
	
	void addHandler( EventHandler eh ) {
		handlers.length = handlers.length + 1;
		handlers[handlers.length - 1] = eh;
	}
	
	void opCall( GLWindow window, Event event ) {
		foreach ( handler; handlers ) {
			handler( window, event );
		}
	}
}

class GLWindow
{
	SDL_Surface* screen;
	int width, height;
	
	this( int width, int height )
	{
		this.width = width;
		this.height = height;
		
		// Initialize SDL
		if(SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO) < 0)
		{
			throw new SDLException( "Unable to init SDL" );
		}

		SDL_GL_SetAttribute( SDL_GL_DOUBLEBUFFER, 1 );

		// Create the screen surface (window)
		screen = SDL_SetVideoMode( this.width, this.height, 32, SDL_HWSURFACE | SDL_OPENGL );
		if(screen is null)
		{
			throw new SDLException( "Unable to set video mode" );
		}
		
		version (darwin) {
			try
			{
				DerelictGL.loadVersions(GLVersion.Version20);
			}
			catch(SharedLibProcLoadException slple)
			{
				// Here, you can check which is the highest version that actually loaded.
				/* Do Something Here */
			}
		
			DerelictGL.loadExtensions( );
		}
		
		setupGL( );
	}
	
	void title( string title )
	{
		SDL_WM_SetCaption( std.string.toStringz(title), std.string.toStringz(title) );
	}
	
	void setupGL( ) {
		glClearColor( 0.0f, 0.0f, 0.0f, 0.0f );

		glViewport( 0, 0, screen.w, screen.h );

		glMatrixMode( GL_PROJECTION );
		glLoadIdentity();

		gluPerspective( 50.0, cast(float)screen.w/cast(float)screen.h, 0.1f, 100.0f );

		glMatrixMode( GL_MODELVIEW );
		glLoadIdentity();
		checkGLErrors( "identity" );

		glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		glEnable(GL_DEPTH_TEST);
		glClearDepth(1.0);				
		glDepthFunc(GL_LEQUAL);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		glEnable(GL_BLEND);
		glAlphaFunc(GL_GREATER,0.01);
		glEnable(GL_ALPHA_TEST);				
		glEnable(GL_TEXTURE_2D);
		checkGLErrors( "texture" );

		//glHint(GL_POINT_SMOOTH, GL_NICEST);
		checkGLErrors( "point smooth" );
		//glHint(GL_LINE_SMOOTH, GL_NICEST);
		checkGLErrors( "line smooth" );
		//glHint(GL_POLYGON_SMOOTH, GL_NICEST);
		checkGLErrors( "polygon smooth" );

		glEnable(GL_POINT_SMOOTH);
		glEnable(GL_LINE_SMOOTH);
		glEnable(GL_POLYGON_SMOOTH);
		checkGLErrors( "setupGL" );
	}
	
	void setOrthographicProjection() {
		// switch to projection mode
		glMatrixMode(GL_PROJECTION);

		// save previous matrix which contains the 
		//settings for the perspective projection
		glPushMatrix();

		// reset matrix
		glLoadIdentity();

		// set a 2D orthographic projection
		gluOrtho2D(0, screen.w, 0, screen.h);
		// invert the y axis, down is positive
		glScalef(1, -1, 1);
		// mover the origin from the bottom left corner
		// to the upper left corner
		glTranslatef(0, -screen.h, 0);
		glMatrixMode(GL_MODELVIEW);
		glPushMatrix( );
	}
	
	void resetPerspectiveProjection() {
		glPopMatrix( );
		glMatrixMode(GL_PROJECTION);
		glPopMatrix();
		glMatrixMode(GL_MODELVIEW);
	}
	
	void ortho( bool enable) {
		if ( enable )
			setOrthographicProjection( );
		else
			resetPerspectiveProjection( );
	}
	
	EventAttribute onRedraw;
	EventAttribute onEvent;
	EventAttribute onKeyUpEvent;
	EventAttribute onKeyDownEvent;
	EventAttribute onMouseUpEvent;
	EventAttribute onMouseDownEvent;
	EventAttribute onMouseMoveEvent;
	
	bool running;
	
	void endLoop( ) {
		running = false;
	}
	
	void runLoop( ) {
		running = true;
		
		// main loop
		while(running)
		{
			SDL_Event event;
			while(SDL_PollEvent(&event))
			{
				Event realEvent = null;
				
				switch(event.type)
				{
					// exit if SDLK or the window close button are pressed
					case SDL_KEYUP:
						realEvent = new KeyUpEvent( event );
						onKeyUpEvent( this, cast(KeyUpEvent)realEvent );
						break;
					case SDL_KEYDOWN:
						realEvent = new KeyDownEvent( event );
						onKeyDownEvent( this, cast(KeyDownEvent)realEvent );
						break;
					case SDL_MOUSEMOTION:
						realEvent = new MouseMoveEvent( event );
						onMouseMoveEvent( this, cast(MouseMoveEvent)realEvent );
						break;
					case SDL_MOUSEBUTTONDOWN:
						realEvent = new MouseDownEvent( event );
						onMouseDownEvent( this, cast(MouseDownEvent)realEvent );
						break;
					case SDL_MOUSEBUTTONUP:
						realEvent = new MouseUpEvent( event );
						onMouseUpEvent( this, cast(MouseUpEvent)realEvent );
						break;
					case SDL_QUIT:
						running = false;
						break;
					default:
						break;
				}
				
				if ( realEvent !is null )
					onEvent( this, realEvent );
			}
			
			SDL_Delay(0);
			
			glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
			
			glDisable( GL_TEXTURE_2D );
			glEnable( GL_TEXTURE_RECTANGLE_ARB );
			checkGLErrors( "ready" );
			
			onRedraw( this, null );
			
			checkGLErrors( "preflush" );
			glFlush( );
			SDL_GL_SwapBuffers();
		}
	}
	
	void grabMouse( bool val ) {
		SDL_WM_GrabInput( val ? SDL_GRAB_ON : SDL_GRAB_OFF );
	}
	
	bool grabMouse( ) {
		return SDL_WM_GrabInput( SDL_GRAB_QUERY ) == SDL_GRAB_ON;
	}
	
	void showCursor( bool val ) {
		SDL_ShowCursor( val ? SDL_ENABLE : SDL_DISABLE );
	}
	
	bool showCursor( ) {
		return SDL_ShowCursor( SDL_QUERY ) == SDL_ENABLE;
	}
}
