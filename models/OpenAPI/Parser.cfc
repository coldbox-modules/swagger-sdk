/**
 * Copyright Ortus Solutions, Corp, All rights reserved
 * www.ortussolutions.com
 * ---
 * Open API Parser
 *
 * BoxLang notes:
 * - Prefer isObject()/isInstanceOf() over isStruct() when a value may be a CFC.
 *   isStruct(cfc) can trigger expensive StructCasterLoose work on BoxLang.
 * - External $ref resolution is request-cached and cycle-safe so shared schemas
 *   (and circular file refs) do not recurse forever in parseDocumentInheritance.
 */
component name="OpenAPIParser" accessors="true" {

	// the base path of the APIDoc
	property name="DocumentObject";
	property name="baseDocumentPath";
	property name="schemaType";
	property name="Wirebox" inject="wirebox";
	property name="jLoader" inject="loader@cbjavaloader";
	property name="Utils"   inject="OpenAPIUtil@SwaggerSDK";

	/**
	 * Constructor
	 * @param APIDocPath		The path of the top-level API description file.  Valid extensions: .json, .yaml, .json.cfm
	 **/
	public function init( string APIDocPath ){
		var refArray = listToArray( arguments.APIDocPath, chr( 35 ) );

		var DocPath = refArray[ 1 ];
		if ( arrayLen( refArray ) > 1 ) {
			var XPath = refArray[ 2 ];
		} else {
			XPath = "";
		}

		if ( left( DocPath, 4 ) != "http" && !fileExists( DocPath ) ) {
			throw(
				type    = "SwaggerSDK.ParserException",
				message = "The APIDoc file #arguments.APIDocPath# does not exist."
			);
		}

		setBaseDocumentPath( DocPath );
		setSchemaType( uCase( listLast( DocPath, "." ) ) );

		var documentContent = "";

		switch ( getSchemaType() ) {
			case "cfm":
				savecontent variable="documentContent" {
					include APath;
				}
				if ( !isJSON( trim( documentContent ) ) ) throwInvalidJSONException( documentContent );

				documentContent = serializeJSON( trim( documentContent ) );

				break;
			case "yaml":
			case "yml":
				documentContent = loadYamlFile( DocPath );
				break;
			case "json":
				if ( left( DocPath, 4 ) == "http" ) {
					var req = new http();
					req.setMethod( "GET" );
					req.setURL( DocPath );
					documentContent = req.send().getPrefix().filecontent;
				} else {
					documentContent = fileRead( DocPath );
				}

				if ( !isJSON( documentContent ) ) throwInvalidJSONException( documentContent );

				documentContent = deserializeJSON( documentContent );

				break;
			default:
				throw(
					type    = "SwaggerSDK.ParserException",
					message = "SwaggerSDK does not support schema using the .#lCase( getSchemaType() )# file extension."
				);
		}

		return parse( documentContent, XPath );
	}


	/**
	 * Parses an API Document recursively
	 *
	 * @param APIDoc		The struct representation of the API Document
	 * @param [XPath]	The XPath to zoom the parsed document to during recursion
	 **/
	public function parse(
		required struct APIDoc,
		required string XPath = ""
	){
		setDocumentObject(
			getWirebox().getInstance( "OpenAPIDocument@SwaggerSDK" ).init( arguments.APIDoc, arguments.XPath )
		);

		parseDocumentInheritance( parseDocumentReferences( getDocumentObject().getDocument() ) );

		return this;
	}

	/**
	 * Loads a linked hash map from a JSON file
	 *
	 * @param JSONData	The raw JSON string
	 **/
	private function loadAsLinkedHashMap( required string JSONData ){
		var JSONFactory = jLoader.create( "com.fasterxml.jackson.core.JsonFactory" );
		var Codec       = jLoader.create( "com.fasterxml.jackson.core.ObjectCodec" );
		var CodecProxy  = createObject(
			"java",
			"coldfusion.runtime.java.JavaProxy"
		).init( Codec );

		var Parser  = JSONFactory.createParser( arguments.JSONData );
		var Mapper  = jLoader.create( "java.util.Map" );
		var HashMap = structNew( "ordered" );

		HashMap.putAll( deserializeJSON( JSONData ) );
	}

	/**
	 * Parses API Document $ref notations recursively
	 *
	 * @param APIDoc		The struct representation of the API Document
	 * @param [XPath]	The XPath to zoom the parsed document to during recursion
	 **/
	public function parseDocumentReferences( required any DocItem ){
		return walkDocumentReferences( arguments.DocItem, {} );
	}


	/**
	 * Parses API Document $extend notations recursively
	 *
	 * @param APIDoc		The struct representation of the API Document
	 * @param [XPath]	The XPath to zoom the parsed document to during recursion
	 **/
	public function parseDocumentInheritance( required any DocItem ){
		return walkDocumentInheritance( arguments.DocItem, {} );
	}


	/**
	 * Extends schema definitions based on the passed array of schema objects
	 * Note: Ignores CFML objects (non-structs) because sometimes the parser gets passed in here for some reason
	 *
	 * @objects
	 */
	function extendObject( array objects ){
		var output = {};
		objects.each( function( item, index ){
			if ( isPlainStruct( item ) ) {
				item.each( function( key, value ){
					if (
						output.keyExists( key ) &&
						isPlainStruct( output[ key ] )
					) {
						output[ key ].append( value, true );
					} else {
						output[ key ] = value
					}
				} );
			}
		} );

		return output;
	}

	/**
	 * Retrieves the value from a nested struct when given an XPath argument
	 *
	 * @param XPath	The XPath to zoom the parsed document to during recursion
	 **/
	public function getInternalXPath( required string XPath ){
		var PathArray = listToArray( XPath, "/" );
		return getDocumentObject().locate( arrayToList( PathArray, "." ) );
	}

	/**
	 * Convenience method to return the fully normalize document
	 **/
	public function getNormalizedDocument(){
		return getDocumentObject().getNormalizedDocument();
	}

	/**
	 * Fetches a document $ref object
	 * @param $ref 	The $ref value
	 **/
	private function fetchDocumentReference( required string $ref ){
		// double pound ## means we want to preserve the swagger $ref pointer (just remove the extra #)
		if ( left( $ref, 2 ) == chr( 35 ) & chr( 35 ) ) {
			return { "$ref" : right( $ref, ( len( $ref ) - 1 ) ) };
			// resolve internal refrences before looking for externals
		} else if ( left( $ref, 1 ) == chr( 35 ) ) {
			var FilePath = "";
			var XPath    = right( $ref, len( $ref ) - 1 );
		} else {
			var refArray = listToArray( $ref, chr( 35 ) );
			var FilePath = refArray[ 1 ];
			if ( arrayLen( refArray ) > 1 ) {
				var XPath = refArray[ 2 ];
				if ( left( XPath, 1 ) == "/" ) {
					XPath = right( XPath, len( XPath ) - 1 );
				}
			}
		}

		var ReferenceDocument = {};

		try {
			// Files receive a parser reference
			if ( left( FilePath, 4 ) == "http" ) {
				ReferenceDocument = parseExternalReference( $ref, $ref );
			} else if ( len( FilePath ) ) {
				var resolvedPath = resolveExternalFilePath( FilePath );
				if ( !len( resolvedPath ) ) {
					throw(
						type    = "SwaggerSDK.ParserException",
						message = "File #describeMissingFile( FilePath )# does not exist"
					);
				}

				var parseTarget   = resolvedPath & ( !isNull( XPath ) && len( XPath ) ? "##" & XPath : "" );
				ReferenceDocument = parseExternalReference( parseTarget, $ref );
			} else if ( !isNull( XPath ) && len( XPath ) ) {
				ReferenceDocument = getInternalXPath( XPath );
			} else {
				throw(
					type    = "SwaggerSDK.ParserException",
					message = "The $ref #$ref# could not be resolved as either an internal or external reference"
				);
			}
		} catch ( any e ) {
			// if this is a known exception or occured via recursion, rethrow the exception so the user knows which JSON file triggered it
			if (
				listFindNoCase(
					"SwaggerSDK.ParserException,CBSwagger.InvalidReferenceDocumentException",
					e.type
				)
			) {
				rethrow;
			}

			throw(
				type    = "CBSwagger.InvalidReferenceDocumentException",
				message = "The $ref file pointer of #$ref# could not be loaded and parsed as a valid object.  If your $ref file content is an array, please nest the array within an object as a named key. The message received was: #e.message# #e.detail#"
			);
		}

		return ReferenceDocument;
	}

	/**
	 * Multi-use error throw
	 * @param InvalidContent 	The content which cause the exception
	 **/
	private function throwInvalidJSONException( required string InvalidContent ){
		throw(
			type    = "SwaggerSDK.ParserException",
			message = "The API Document Provided: #getBaseDocumentPath()# could not be converted to valid JSON"
		);
	}

	/********************************************************************************/
	/*  PRIVATE HELPERS
	/********************************************************************************/

	/**
	 * Walk $ref nodes with identity-based cycle detection.
	 */
	private function walkDocumentReferences(
		required any DocItem,
		required struct visited
	){
		arguments.DocItem = flattenParserInstance( arguments.DocItem );

		if ( isArray( arguments.DocItem ) ) {
			for ( var i = 1; i <= arrayLen( arguments.DocItem ); i++ ) {
				arguments.DocItem[ i ] = walkDocumentReferences(
					arguments.DocItem[ i ],
					arguments.visited
				);
			}
			return arguments.DocItem;
		}

		if ( !isPlainStruct( arguments.DocItem ) ) {
			return arguments.DocItem;
		}

		var visitKey = identityKey( arguments.DocItem );
		if ( structKeyExists( arguments.visited, visitKey ) ) {
			return arguments.DocItem;
		}
		arguments.visited[ visitKey ] = true;

		// handle top-level values, if they exist
		if ( structKeyExists( arguments.DocItem, "$ref" ) ) {
			// special handling for double pound signs — preserve as a single-# OpenAPI pointer
			if ( left( arguments.DocItem[ "$ref" ], 2 ) == chr( 35 ) & chr( 35 ) ) {
				arguments.DocItem[ "$ref" ] = right(
					arguments.DocItem[ "$ref" ],
					( len( arguments.DocItem[ "$ref" ] ) - 1 )
				);
				return arguments.DocItem;
			}
			return assignFetchedReference(
				arguments.DocItem[ "$ref" ],
				arguments.visited
			);
		}

		for ( var key in arguments.DocItem ) {
			if ( isNull( arguments.DocItem[ key ] ) ) {
				arguments.DocItem[ key ] = nullValue();
				continue;
			}

			var child                = flattenParserInstance( arguments.DocItem[ key ] );
			arguments.DocItem[ key ] = child;

			if ( isPlainStruct( child ) && structKeyExists( child, "$ref" ) ) {
				arguments.DocItem[ key ] = assignFetchedReference( child[ "$ref" ], arguments.visited );
			} else if ( isPlainStruct( child ) || isArray( child ) ) {
				arguments.DocItem[ key ] = walkDocumentReferences( child, arguments.visited );
			}
		}

		return arguments.DocItem;
	}

	/**
	 * Fetch a $ref and decide whether to re-walk the result.
	 * External file/HTTP parses are already fully walked inside init()/parse() —
	 * re-walking them would resolve preserved `#/…` pointers against the wrong document.
	 */
	private any function assignFetchedReference(
		required string ref,
		required struct visited
	){
		var resolved = fetchDocumentReference( arguments.ref );

		// Cycle breaker / unresolved lone pointer
		if (
			isPlainStruct( resolved )
			&&
			structKeyExists( resolved, "$ref" )
			&&
			structCount( resolved ) == 1
		) {
			return resolved;
		}

		// External targets are complete; internal # fragments may still contain nested $refs
		if ( isExternalRef( arguments.ref ) ) {
			return resolved;
		}

		return walkDocumentReferences( resolved, arguments.visited );
	}

	/**
	 * True when $ref points at an external file or URL (not an in-document # pointer).
	 */
	private boolean function isExternalRef( required string ref ){
		if ( !len( arguments.ref ) ) {
			return false;
		}
		if ( left( arguments.ref, 1 ) == chr( 35 ) ) {
			return false;
		}
		return true;
	}

	/**
	 * Walk $extend / nested structs with identity-based cycle detection.
	 */
	private function walkDocumentInheritance(
		required any DocItem,
		required struct visited
	){
		arguments.DocItem = flattenParserInstance( arguments.DocItem );

		if ( isArray( arguments.DocItem ) ) {
			for ( var i = 1; i <= arrayLen( arguments.DocItem ); i++ ) {
				arguments.DocItem[ i ] = walkDocumentInheritance(
					arguments.DocItem[ i ],
					arguments.visited
				);
			}
			return arguments.DocItem;
		}

		if ( !isPlainStruct( arguments.DocItem ) ) {
			return arguments.DocItem;
		}

		var visitKey = identityKey( arguments.DocItem );
		if ( structKeyExists( arguments.visited, visitKey ) ) {
			return arguments.DocItem;
		}
		arguments.visited[ visitKey ] = true;

		// handle top-level extension
		if ( structKeyExists( arguments.DocItem, "$extend" ) ) {
			return extendObject(
				walkDocumentInheritance(
					arguments.DocItem[ "$extend" ],
					arguments.visited
				)
			);
		}

		for ( var key in arguments.DocItem ) {
			if ( isNull( arguments.DocItem[ key ] ) ) {
				arguments.DocItem[ key ] = nullValue();
				continue;
			}

			var child                = flattenParserInstance( arguments.DocItem[ key ] );
			arguments.DocItem[ key ] = child;

			if ( isPlainStruct( child ) || isArray( child ) ) {
				arguments.DocItem[ key ] = walkDocumentInheritance( child, arguments.visited );
			}
		}

		return arguments.DocItem;
	}

	/**
	 * True for CFML/BoxLang structs (and Java Maps), false for CFC/class instances.
	 * Never call isStruct() on a value that may be a Parser CFC — BoxLang can spin in StructCasterLoose.
	 */
	private boolean function isPlainStruct( required any value ){
		if ( isNull( arguments.value ) ) {
			return false;
		}
		if ( isParserInstance( arguments.value ) ) {
			return false;
		}
		if ( isObject( arguments.value ) ) {
			// Allow Java Map implementations through; reject other objects/CFCs.
			try {
				return isInstanceOf( arguments.value, "java.util.Map" );
			} catch ( any e ) {
				return false;
			}
		}
		return isStruct( arguments.value );
	}

	/**
	 * Detect OpenAPIParser instances without using isStruct(cfc) or getMetadata().
	 * Prefer isInstanceOf; duck-type on normalization entry points as a fallback.
	 */
	private boolean function isParserInstance( required any value ){
		if ( isNull( arguments.value ) || !isObject( arguments.value ) ) {
			return false;
		}
		try {
			if (
				isInstanceOf(
					arguments.value,
					"SwaggerSDK.models.OpenAPI.Parser"
				)
			) {
				return true;
			}
		} catch ( any e ) {
			// isInstanceOf can throw on some non-CFC hosts; fall through to duck-type
		}

		return structKeyExists( arguments.value, "getNormalizedDocument" )
			&& structKeyExists( arguments.value, "getDocumentObject" );
	}

	/**
	 * Replace a Parser CFC with its normalized document struct.
	 */
	private any function flattenParserInstance( required any value ){
		if ( isParserInstance( arguments.value ) ) {
			return arguments.value.getNormalizedDocument();
		}
		return arguments.value;
	}

	/**
	 * Stable identity key for cycle detection across struct/object graphs.
	 */
	private string function identityKey( required any value ){
		return createObject( "java", "java.lang.System" ).identityHashCode( arguments.value );
	}

	/**
	 * Prefer bx-yaml BIFs when present; otherwise use the shipped SnakeYAML jar.
	 * BoxLang production often lacks bx-yaml even though server.boxlang is set.
	 */
	private boolean function canUseBoxlangYamlBifs(){
		if ( !server.keyExists( "boxlang" ) ) {
			return false;
		}
		var functions = getFunctionList();
		return structKeyExists( functions, "yamlDeserialize" )
			&& structKeyExists( functions, "yamlSerialize" );
	}

	/**
	 * Load a YAML/YML file into a CFML struct/array graph.
	 */
	private any function loadYamlFile( required string path ){
		if ( canUseBoxlangYamlBifs() ) {
			return yamlDeserialize( fileRead( arguments.path ) );
		}

		var YAMLLoader  = jLoader.create( "org.yaml.snakeyaml.Yaml" );
		var IOFile      = jLoader.create( "java.io.File" ).init( arguments.path );
		var InputStream = jLoader.create( "java.io.FileInputStream" ).init( IOFile );

		return getUtils().toCF( YAMLLoader.load( InputStream ) );
	}

	/**
	 * Request-scoped cache for external $ref parses (done + in-flight).
	 */
	private struct function getRefParseCache(){
		if ( !structKeyExists( request, "__swaggerSDKRefParseCache" ) ) {
			request.__swaggerSDKRefParseCache = { "done" : {}, "pending" : {} };
		}
		return request.__swaggerSDKRefParseCache;
	}

	/**
	 * Parse an external $ref target once per request; break file-level cycles.
	 * Returns a normalized document struct (never a Parser CFC).
	 */
	private any function parseExternalReference(
		required string parseTarget,
		required string originalRef
	){
		var cache    = getRefParseCache();
		var cacheKey = arguments.parseTarget;

		if ( structKeyExists( cache.done, cacheKey ) ) {
			return cache.done[ cacheKey ];
		}

		// Circular file $ref: return a preserved OpenAPI pointer instead of recursing.
		if ( structKeyExists( cache.pending, cacheKey ) ) {
			return { "$ref" : arguments.originalRef };
		}

		cache.pending[ cacheKey ] = true;
		try {
			var parserInstance = Wirebox.getInstance( "OpenAPIParser@SwaggerSDK" ).init( arguments.parseTarget );
			var normalized     = isParserInstance( parserInstance )
			 ? parserInstance.getNormalizedDocument()
			 : parserInstance;
			cache.done[ cacheKey ] = normalized;
			return normalized;
		} finally {
			structDelete( cache.pending, cacheKey );
		}
	}

	/**
	 * Resolve an external file $ref to an absolute filesystem path.
	 * Prefer absolute/web-root paths via expandPath; only join to the base document directory for relatives.
	 */
	private string function resolveExternalFilePath( required string filePath ){
		var candidate = "";

		// Absolute filesystem or web-root path: do not concatenate onto the current document directory
		// (that produced paths like /app/resources/api/auth//resources/api/pagination.json).
		if (
			left( arguments.filePath, 1 ) == "/"
			||
			reFindNoCase(
				"^[A-Za-z]:[\\/]",
				arguments.filePath
			)
		) {
			candidate = arguments.filePath;
			if ( fileExists( candidate ) ) {
				return candidate;
			}
			try {
				candidate = expandPath( arguments.filePath );
				if ( fileExists( candidate ) ) {
					return candidate;
				}
			} catch ( any e ) {
				// continue
			}
			return "";
		}

		// Relative to the current document (e.g. ./schema.yml)
		var basePath = "";
		try {
			basePath = getBaseDocumentPath();
		} catch ( any e ) {
			basePath = "";
		}
		if ( !isNull( basePath ) && len( basePath ) ) {
			var baseDir = getDirectoryFromPath( basePath );
			// BoxLang: getDirectoryFromPath("") can be "/", which yields "//relative"
			if ( len( baseDir ) && baseDir != "/" && baseDir != "\" ) {
				candidate = baseDir & arguments.filePath;
				candidate = replace( candidate, "\", "/", "all" );
				candidate = reReplace( candidate, "/{2,}", "/", "all" );
				candidate = replace( candidate, "/./", "/", "all" );
				if ( fileExists( candidate ) ) {
					return candidate;
				}
			}
		}

		try {
			candidate = expandPath( arguments.filePath );
			if ( fileExists( candidate ) ) {
				return candidate;
			}
		} catch ( any e ) {
			// continue
		}

		return "";
	}

	/**
	 * Human-readable missing-file message (avoids BoxLang empty-base "//path" noise when possible).
	 */
	private string function describeMissingFile( required string filePath ){
		try {
			var basePath = getBaseDocumentPath();
			if ( !isNull( basePath ) && len( basePath ) ) {
				var baseDir = getDirectoryFromPath( basePath );
				if ( len( baseDir ) && baseDir != "/" && baseDir != "\" ) {
					return baseDir & arguments.filePath;
				}
			}
		} catch ( any e ) {
			// fall through
		}
		try {
			return expandPath( arguments.filePath );
		} catch ( any e ) {
			return arguments.filePath;
		}
	}

}
