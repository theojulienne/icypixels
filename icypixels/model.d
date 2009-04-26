module icypixels.model;

import icypixels.vector;
import icypixels.texture;
import icypixels.xml;

import std.compat;
import std.stdio;
import std.string;
import std.path;

import derelict.opengl.gl;

void append( T )( inout T[] ns, T n ) {
	int idx = ns.length;
	ns.length = idx + 1;
	ns[idx] = n;
}

abstract class Model {
	void render( ) {
		
	}
}

class ColladaRenderContext {
	string idBinding[string];
	
	this( ) {
		
	}
	
	void bind( string source, string dest ) {
		idBinding[source] = dest;
	}
	
	string getBinding( string source, string defaultReturn ) {
		try {
			return idBinding[source];
		} catch ( Exception e ){
			return defaultReturn;
		}
	}
	
	bool hasBinding( string source ) {
		return ( source in idBinding ) !is null;
	}
}

class ColladaModel : Model {
	//Texture[string] textures;
	Object[string] idMap;
	
	class Material {
		string effectUrl;
		
		void enable( ColladaRenderContext ctx ) {
			Effect effect = cast(Effect)idMap[effectUrl[1..$]];
			effect.enable( ctx );
		}
		
		void disable( ColladaRenderContext ctx ) {
			Effect effect = cast(Effect)idMap[effectUrl[1..$]];
			effect.disable( ctx );
		}
		
		Image image( ) {
			Effect effect = cast(Effect)idMap[effectUrl[1..$]];
			try {
				Image image = cast(Image)idMap[effect.textureId];
				return image;
			} catch {
				return null;
			}
		}
	}
	
	Material[string] materials;
	
	Material addMaterial( string id ) {
		Material m = new Material;
		materials[id] = m;
		idMap[id] = m;
		return m;
	}
	
	
	class Effect {
		string textureId;
		
		void enable( ColladaRenderContext ctx ) {
			glColor4f( 1.0f, 1.0f, 1.0f, 1.0f );
			
			if ( textureId is null )
				return;
			
			writefln( "%s %s", ctx.getBinding(textureId,null), textureId );
			
			Image image = cast(Image)idMap[ctx.getBinding(textureId,textureId)];
			image.enable( );
		}
		
		void disable( ColladaRenderContext ctx ) {
			if ( textureId is null )
				return;
			
			Image image = cast(Image)idMap[ctx.getBinding(textureId,textureId)];
			image.disable( );
		}
	}
	
	Effect[string] effects;
	
	Effect addEffect( string id ) {
		Effect e = new Effect;
		effects[id] = e;
		idMap[id] = e;
		return e;
	}
	
	
	class Image {
		Texture tex;
		
		void loadFromFile( string filename ) {
			tex = new ImageTexture( filename );
		}
		
		void enable( ) {
			tex.activate( );
		}
		
		void disable( ) {
			tex.deactivate( );
		}
		
		Texture texture( ) {
			return tex;
		}
	}
	
	Image[string] images;
	
	Image addImage( string id ) {
		Image i = new Image;
		images[id] = i;
		idMap[id] = i;
		return i;
	}
	
	
	struct Input {
		string semantic;
		string source;
		int offset;
		int set;
		
		T getFromData( T )( T[] data, uint numInputs, int index ) {
			return data[(index*numInputs) + offset];
		}
	}
	
	class Geometry {
		class Mesh {
			class Source {
				class Accessor {
					int count;
					int stride;
					
					int[string] params;
					
					float get( string name, int sourceIndex ) {
						return data[(sourceIndex*stride) + params[name]];
					}
				}
				
				float[] data;
				
				Accessor accessor;
				
				this( ) {
					accessor = new Accessor;
				}
			}
			
			Source[string] sources;
			
			Source addSource( string id ) {
				Source s = new Source;
				sources[id] = s;
				idMap[id] = s;
				return s;
			}
			
			float sourceData( Input input, string name, int sourceIndex ) {
				string sourceName = input.source[1..$];
				
				auto dataSource = sources[sourceName];

				return dataSource.accessor.get( name, sourceIndex );
			}
			
			
			class Primitive {
				int[] data;
				Input[string] inputs;
				string materialId;
				
				void addInput( string semantic, string source, int offset, int set=0 ) {
					Input i;
					i.semantic = semantic;
					i.source = source;
					i.offset = offset;
					i.set = set;
					inputs[semantic] = i;
				}
				
				void render( ColladaRenderContext ctx ) {
					
				}
			}
			
			class TrianglesPrimitive : Primitive {
				float[] vertData;
				int vertStride;
				uint[] indices;
				bool prepared = false;
				
				// converts from COLLADA style storage to raw arrays for OpenGL
				void prepare( ColladaRenderContext ctx ) {
					prepared = true;
					
					int dataStride = inputs.length * 3;
					int numTriangles = data.length / dataStride;
					vertStride = 3 + 3 + 2; // XYZ + NNN + UV
					
					vertData.length = numTriangles * 3 * vertStride;
					indices.length = numTriangles * 3;
					
					writefln( "%s", numTriangles );
					
					for ( int v = 0; v < numTriangles * 3; v++ ) {
						int i = v * vertStride;
						
						// XYZ
						int XYZindex = inputs["VERTEX"].getFromData( data, inputs.length, v );
						vertData[i+0] = sourceData( inputs["VERTEX"], "X", XYZindex );
						vertData[i+1] = sourceData( inputs["VERTEX"], "Y", XYZindex ); 
						vertData[i+2] = sourceData( inputs["VERTEX"], "Z", XYZindex );
						//writefln( "[%s] %s, %s, %s", XYZindex, vertData[i+0], vertData[i+1], vertData[i+2] );
						// NNN
						int NORindex = inputs["NORMAL"].getFromData( data, inputs.length, v );
						vertData[i+3] = sourceData( inputs["NORMAL"], "X", NORindex );
						vertData[i+4] = sourceData( inputs["NORMAL"], "Y", NORindex );
						vertData[i+5] = sourceData( inputs["NORMAL"], "Z", NORindex );
						// UV
						if ( "TEXCOORD" in inputs ) {
							float tw = 1.0f;
							float th = 1.0f;
							
							string mappedMaterialId = ctx.getBinding(materialId, "#"~materialId)[1..$];
							Material mat = cast(Material)idMap[mappedMaterialId];
							Image img = mat.image;
							if ( img !is null ) {
								Texture tex = img.texture;
								
								tw = tex.w;
								th = tex.h;
							}
							
							int UVindex = inputs["TEXCOORD"].getFromData( data, inputs.length, v );
							vertData[i+6] = sourceData( inputs["TEXCOORD"], "S", UVindex ) * tw;
							vertData[i+7] = (1-sourceData( inputs["TEXCOORD"], "T", UVindex )) * th;
						}
						
						indices[v] = v;
					}
				}
				
				void render( ColladaRenderContext ctx ) {
					if ( !prepared ) {
						prepare( ctx );
					}
					
//					writefln( "stride=%s", vertStride );	
					
					glEnableClientState( GL_VERTEX_ARRAY );
					glVertexPointer( 3, GL_FLOAT, vertStride*float.sizeof, vertData.ptr );
					
					glEnableClientState( GL_NORMAL_ARRAY );
					glNormalPointer( GL_FLOAT, vertStride*float.sizeof, vertData.ptr+3 );

					Material mat;

					if ( "TEXCOORD" in inputs ) {
						glEnableClientState( GL_TEXTURE_COORD_ARRAY );
						glTexCoordPointer( 2, GL_FLOAT, vertStride*float.sizeof, vertData.ptr+6 );
						
						// enable texture
						string mappedMaterialId = ctx.getBinding(materialId, "#"~materialId)[1..$];
						mat = cast(Material)idMap[mappedMaterialId];
						mat.enable( ctx );
					}

					glDrawElements( GL_TRIANGLES, indices.length, GL_UNSIGNED_INT, indices.ptr );

					glDisableClientState( GL_VERTEX_ARRAY );
					glDisableClientState( GL_NORMAL_ARRAY );
					if ( "TEXCOORD" in inputs ) {
						glDisableClientState( GL_TEXTURE_COORD_ARRAY );
						mat.disable( ctx );
					}
				}
			}
			
			Primitive[] primitives;
			
			TrianglesPrimitive addTrianglesPrimitive( ) {
				TrianglesPrimitive tp = new TrianglesPrimitive;
				primitives.append( tp );
				return tp;
			}
			
			void render( ColladaRenderContext bindMaterial ) {
				foreach ( primitive; primitives ) {
					primitive.render( bindMaterial );
				}
			}
		}
		
		Mesh mesh;
		
		this( ) {
			mesh = new Mesh;
		}
		
		void render( ColladaRenderContext ctx ) {
			mesh.render( ctx );
		}
	}
	
	Geometry[string] geometries;
	
	Geometry addGeometry( string id ) {
		Geometry g = new Geometry;
		geometries[id] = g;
		idMap[id] = g;
		return g;
	}
	
	
	class VisualScene {
		string id;
		
		class Node {
			string id;
			
			class Instance {
				void render( ) {
					
				}
			}
			
			class InstanceGeometry : Instance {
				string url;
				string[string] bindMaterial;
				
				void render( ) {
					assert( url[0] == '#', "Only know how to reference ID-based URLs" );
					
					Object obj = idMap[url[1..$]];
					
					Geometry geom = cast(Geometry)obj;
					
					ColladaRenderContext ctx = new ColladaRenderContext;
					foreach ( src, dst; bindMaterial ) {
						ctx.bind( src, dst );
					}
					
					geom.render( ctx );
				}
			}
			
			Instance[] instances;
			
			InstanceGeometry addInstanceGeometry( ) {
				InstanceGeometry ig = new InstanceGeometry;
				instances.append( ig );
				return ig;
			}
			
			void render( ) {
				foreach ( instance; instances ) {
					instance.render( );
				}
			}
		}
		
		Node[string] nodes;
		
		Node addNode( string id ) {
			Node n = new Node;
			nodes[id] = n;
			idMap[id] = n;
			return n;
		}
		
		void render( ) {
			foreach ( node; nodes ) {
				node.render( );
			}
		}
	}
	
	VisualScene scene;
	
	this( ) {
		scene = new VisualScene;
	}
	
	void render( ) {
		scene.render( );
	}
	
	static Model loadDAE( string filename ) {
		ColladaModel m = new ColladaModel;
		
		Xml.Document doc = Xml.fromFile( filename );
		
		auto collada = doc.rootNode["COLLADA"][0];
		
		foreach ( geomNode; collada["library_geometries"][0]["geometry"] ) {
			auto meshNode = geomNode["mesh"][0];
			
			auto geometry = m.addGeometry( geomNode.attributes["id"] );
			auto mesh = geometry.mesh;
			
			// pull out all the sources
			foreach ( sourceNode; meshNode["source"] ) {
				auto floatArray = sourceNode["float_array"][0];
				
				auto source = mesh.addSource( sourceNode.attributes["id"] );
				
				string[] vals = split( floatArray.innerData, " " );
				
				if ( vals[$-1] == "" )
					vals.length = vals.length - 1;
				
				float[] farr;
				farr.length = vals.length;
				
				assert( vals.length == atoi(floatArray.attributes["count"]), "float_array count attribute does not match content" );
				
				foreach ( i, val; vals ) {
					farr[i] = atof(val);
				}
				
				source.data = farr;
				
				auto accessorNode = sourceNode["technique_common"][0]["accessor"][0];
				auto accessor = source.accessor;
				
				accessor.count = atoi(accessorNode.attributes["count"]);
				accessor.stride = atoi(accessorNode.attributes["stride"]);
				
				foreach ( i, paramNode; accessorNode["param"] ) {
					try {
						accessor.params[paramNode.attributes["name"]] = i;
					} catch {
						continue;
					}
				}
			}
			
			// vertices tag (which seems about as useful as a pointer to a pointer to a pointer)
			auto verticesNode = meshNode["vertices"][0];
			auto verticesInputNode = verticesNode["input"][0];
			assert( verticesInputNode.attributes["semantic"] == "POSITION" );
			
			auto verticesName = verticesNode.attributes["id"];
			auto verticesPositionName = verticesInputNode.attributes["source"];
			
			// pull out the triangles
			foreach ( triangles; meshNode["triangles"] ) {
				auto materialId = triangles.attributes["material"];
				auto triCount = atoi(triangles.attributes["count"]);
				auto primitiveNode = triangles["p"][0];
				
				auto primitive = mesh.addTrianglesPrimitive( );
				primitive.materialId = materialId;
				
				foreach ( input; triangles["input"] ) {
					auto inputSemantic = input.attributes["semantic"];
					auto inputSource = input.attributes["source"];
					auto inputOffset = atoi( input.attributes["offset"] );
					//auto inputSet = input.attributes["set"];
					
					// this is a hack to bypass the pointer to a pointer
					if ( inputSource == "#" ~ verticesName ) 
						inputSource = verticesPositionName;
					
					primitive.addInput( inputSemantic, inputSource, inputOffset );
				}
				
				auto primitiveContent = primitiveNode.innerData;
				auto indices = primitiveContent.split( " " );
				
				// remove empty element
				if ( indices[$-1] == "" )
					indices.length = indices.length - 1;
				
				int[] indicesInt;
				indicesInt.length = indices.length;
				
				foreach ( i, index; indices ) {
					indicesInt[i] = atoi(index);
				}
				
				primitive.data = indicesInt;
			}
		}
		
		
		auto scene = collada["scene"][0];
		auto vsInst = scene["instance_visual_scene"][0];
		
		auto vsID = vsInst.attributes["url"][1..$];
		auto visualSceneNode = doc.getElementById( vsID );
		
		auto visualScene = m.scene;
		
		void addAllNodes( Xml.Document.Element[] nodes ) {
			foreach ( nodeNode; nodes ) {
				auto nodeId = nodeNode.attributes["id"];
			
				auto node = visualScene.addNode( nodeId );
			
				foreach ( instance_geometry; nodeNode["instance_geometry"] ) {
					auto geomUrl = instance_geometry.attributes["url"];
				
					auto ig = node.addInstanceGeometry( );
					ig.url = geomUrl;
					
					auto bind_materials = instance_geometry["bind_material"];
					if ( bind_materials.length > 0 ) {
						auto bind_material = bind_materials[0];
						auto technique = bind_material["technique_common"][0];
						
						auto instance_materials = technique["instance_material"];
						foreach ( instance_material; instance_materials ) {
							auto target = instance_material.attributes["target"];
							auto symbol = instance_material.attributes["symbol"];
							//writefln( "bind %s to name %s", instance_material.attributes["target"], instance_material.attributes		["symbol"] );
							ig.bindMaterial[symbol] = target;
						}
					}
				}
				
				addAllNodes( nodeNode["node"] );
			}
		}
		
		addAllNodes( visualSceneNode["node"] );
		
		auto libraryMaterials = collada["library_materials"][0]["material"];
		foreach ( materialNode; libraryMaterials ) {
			auto materialId = materialNode.attributes["id"];
			auto effectUrl = materialNode["instance_effect"][0].attributes["url"];
			
			auto material = m.addMaterial( materialId );
			material.effectUrl = effectUrl;
		}
		
		auto libraryEffects = collada["library_effects"][0]["effect"];
		foreach ( effectNode; libraryEffects ) {
			auto effectId = effectNode.attributes["id"];
			
			auto effect = m.addEffect( effectId );
			
			// CHEAP HACK
			
			auto technique = effectNode["profile_COMMON"][0]["technique"][0];
			Xml.Document.Element renderingTechnique;
			
			foreach ( rt; technique.children ) {
				// cast to Element only if valid
				Xml.Document.Element el = cast(Xml.Document.Element)rt;
				
				if ( el !is null ) {
					// use first element
					renderingTechnique = el;
					break;
				}
			}
			
			//auto phong = technique["lambert"][0];
			
			auto diffuse = renderingTechnique["diffuse"][0];
			try {
				auto texture = diffuse["texture"][0];
			
				effect.textureId = texture.attributes["texture"];
			} catch {
				// doesn't have texture
			}
		}
		
		auto libraryImages = collada["library_images"][0]["image"];
		foreach ( imageNode; libraryImages ) {
			auto imageId = imageNode.attributes["id"];
			
			auto image = m.addImage( imageId );
			
			auto imagePath = imageNode["init_from"][0].innerData;
			
			image.loadFromFile( getDirName(filename) ~ "/" ~ imagePath );
		}
		
		/*
		auto libraryImages = collada["library_images"][0]["image"];
		writefln( "%s", libraryImages );
		
		auto libraryMaterials = collada["library_materials"][0]["material"];
		writefln( "%s", libraryMaterials );
		
		auto libraryEffects = collada["library_effects"][0]["effect"];
		writefln( "%s", libraryEffects );
		
		auto libraryGeometries = collada["library_geometries"][0]["geometry"];
		writefln( "%s", libraryGeometries );
		
		auto libraryVisualScenes = collada["library_visual_scenes"][0]["visual_scene"];
		writefln( "%s", libraryVisualScenes );
		*/
		
		return m;
	}
}