module icypixels.xml;

// i can't believe i had to write this because the others were so overcomplicated and broken.
// or maybe i can believe it.

version (Tango) import std.compat;
import std.file;
import std.stdio;
import std.string;

T min( T )( T a, T b ) {
	return a < b ? a : b;
}

// FIXME: comments don't work when they contain '>'
static class Xml {
	static class Document {
		Element[string] elementIds;
		
		Element getElementById( string id ) {
			return elementIds[id];
		}
		
		class Node {
			string data;
			Node[] children;
			
			this( ) {
				
			}
			
			this( string _data ) {
				data = _data;
			}
			
			void appendNode( Node n ) {
				int el = children.length;
				children.length = el+1;
				children[el] = n;
			}
			
			void print( int indent=0 ) {
				for ( int i = 0; i < indent; i++ ) writef( " " );
				writefln( "%s", this );
				foreach ( child; children )
					child.print( indent + 1 );
			}
			
			string toString( ) {
				return format( "<Node>" );
			}
			
			// returns the inner CDATA nodes
			string innerData( ) {
				string outData = "";
				
				foreach ( child; children ) {
					if ( child.data is null )
						continue;
					
					outData ~= child.data;
				}
				
				return outData;
			}
		}
		
		class Element : Node {
			string name;
			string[string] attributes;
			
			this( ) {
				name = null;
			}
			
			void parseTag( string tag ) {
				string tagContent = tag[1..$-1];
				
				// trim trailing '/', ' ' and '?' characters
				while ( tagContent[$-1] == '/' || tagContent[$-1] == ' ' || tagContent[$-1] == '?' )
					tagContent = tagContent[0..$-1];
				
				Parser p = new Parser( tagContent );
				p.parseTagContent( this );
			}
			
			string toString( ) {
				return format( "<Element:%s>", name );
			}
			
			Element getElementById( string id ) {
				foreach ( child; children ) {
					Element el = cast(Element)child;
					
					if ( el is null )
						continue; // CDATA, not an element
					
					if ( !("id" in el.attributes) )
						continue;
					
					if ( el.attributes["id"] == id )
						return el;
				}
				
				return null;
			}
			
			Element[] opIndex( string tagName ) {
				Element[] els;
				
				foreach ( child; children ) {
					Element el = cast(Element)child;
					
					if ( el is null )
						continue; // CDATA, not an element
					
					if ( el.name != tagName )
						continue;
					
					int index = els.length;
					els.length = index+1;
					els[index] = el;
				}
				
				return els;
			}
			
			void setAttribute( string name, string value ) {
				attributes[name] = value;
				
				if ( name == "id" )
					elementIds[value] = this;
			}
		}
		
		class Parser {
			string xml;
			int currentPosition;
			
			this( string xml ) {
				this.xml = xml;
				this.currentPosition = 0;
			}
			
			char peek( int offset ) {
				return xml[currentPosition + offset];
			}
			
			char pop( ) {
				char tmp = xml[currentPosition];
				currentPosition++;
				return tmp;
			}
			
			char[] popString( int popLength ) {
				assert( popLength >= 0, "Can't pop negative number of characters" );
				char[] tmp = xml[currentPosition..currentPosition+popLength];
				currentPosition += popLength;
				return tmp;
			}
			
			bool endOfData( ) {
				return charsLeft <= 0;
			}
			
			int charsLeft( ) {
				return xml.length - currentPosition;
			}
			
			int offsetTo( char c ) {
				int a = 0;
				
				while ( a < charsLeft ) {
					if ( peek( a ) == c )
						return a;
					a++;
				}
				
				return -1;
			}
			
			int offsetTo( char[] y ) {
				int a = 0;
				
				while ( a < charsLeft ) {
					bool found = true;
					foreach ( i, c; y ) { // couldn't resist
						if ( peek( i ) != c ) {
							found = false;
							break;
						}
					}
					if ( found )
						return a;
					a++;
				}
				
				return -1;
			}
			
			void parseTagContent( Element target ) {
				int sepPos = offsetTo( ' ' );
				
				if ( sepPos == -1 )
					sepPos = offsetTo( '/' );
				
				if ( sepPos == -1 )
					sepPos = offsetTo( '>' );
				
				if ( sepPos == -1 )
					sepPos = charsLeft;
				
				target.name = popString( sepPos );
				
				while ( !endOfData ) {
					// skip spaces
					while ( !endOfData && peek(0) == ' ' )
						pop( );
					
					if ( endOfData )
						break;

					int tmpPos;
					sepPos = offsetTo( '=' );
					tmpPos = offsetTo( ' ' );
					
					if ( sepPos == -1 || (tmpPos != -1 && tmpPos < sepPos) )
						sepPos = tmpPos;
					
					string attrName = popString( sepPos );
					
					assert( peek(0) == '=', "Attributes with no value not supported" );
					pop( );
					
					assert( peek(0) == '"', "Attributes without quotes not supported" );
					pop( );
					
					string attrValue = popString( offsetTo( '"' ) );
					pop( ); // trailing quote
					
					target.setAttribute( attrName, attrValue );
				}
			}
			
			void parseNodes( Element parent ) {
				while ( !endOfData ) {
					char first = peek( 0 );
					
					Node newNode;
					
					if ( first == '<' ) {
						// comment?
						if ( peek( 1 ) == '!' && peek( 2 ) == '-' && peek( 3 ) == '-' ) {
							// find end of comment
							int tagLength = offsetTo( "-->" ) + 3; // include the end
							assert( tagLength != -1 );
							
							string tag = popString( tagLength );
							
							continue;
						}
						
						// tag
						int tagLength = offsetTo( '>' ) + 1; // include this character
						
						string tag = popString( tagLength );
						
						if ( parent.name !is null && tag == format( "</%s>", parent.name ) ) {
							return;
						}
						
						Element el = new Element;
						el.parseTag( tag );
						newNode = el;
						
						if ( tag[$-2] != '/' && (tag[0] != '?' && tag[$-2] != '?') ) {
							parseNodes( el );
						}
					} else {
						// cdata
						int dataLength = offsetTo( '<' ); // not including this character
						
						if ( dataLength < 0 ) dataLength = charsLeft;
						
						string cdata = popString( dataLength );
						
						newNode = new Node( cdata );
					}
					
					parent.appendNode( newNode );
				}
			}
		}
		
		Element rootNode;
		
		void parseString( string xml ) {
			Parser p = new Parser( xml );
			
			rootNode = new Element;
			
			p.parseNodes( rootNode );
		}
	}
	
	static Document fromFile( string filename ) {
		auto xml = cast(char[])read( filename );
		
		return fromString( xml );
	}
	
	static Document fromString( string xml ) {
		Document doc = new Document;
		doc.parseString( xml );
		return doc;
	}
}
