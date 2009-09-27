module icypixels.texturecache;

version (Tango) import std.compat;
import icypixels.all;

class TextureCache {
	static Texture[string] textures;
	
	static Texture loadTexture( string filename, bool delayedLoad=true ) {
		if ( filename in textures ) {
			return textures[filename];
		}
		
		textures[filename] = new ImageTexture( filename );
		
		if ( delayedLoad ) {
			ThreadedLoader.globalLoader.queueObject( textures[filename] );
		} else {
			ThreadedLoader.globalLoader.loadImmediate( textures[filename] );
		}
		
		return textures[filename];
	}
	
	static Texture loadTextureNow( string filename ) {
		return loadTexture( filename, false );
	}
}
