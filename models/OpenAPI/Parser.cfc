/**
* Copyright Ortus Solutions, Corp, All rights reserved
* www.ortussolutions.com
* ---
* Open API Parser
*/
component name="OpenAPIParser" accessors="true" {
	//the base path of the APIDoc
	property name="DocumentObject";
	property name="baseDocumentPath";
	property name="schemaType";
	property name="Wirebox" inject="wirebox";
	property name="jLoader" inject="loader@cbjavaloader";
	property name="Utils" inject="OpenAPIUtil@SwaggerSDK";

	/**
	* Constructor
	* @param APIDocPath		The path of the top-level API description file.  Valid extensions: .json, .yaml, .json.cfm
	**/
	public function init( string APIDocPath ){

		var refArray = listToArray( arguments.APIDocPath, chr( 35 ) );

		var DocPath = refArray[ 1 ];
		if( arrayLen( refArray ) > 1 ) {
			var XPath = refArray[ 2 ];
		} else {
			XPath="";
		}

		if( left( DocPath, 4 ) != 'http' && !fileExists( DocPath ) ) {
			throw(  type="SwaggerSDK.ParserException", message="The APIDoc file #arguments.APIDocPath# does not exist." );
		}

		setBaseDocumentPath( DocPath );
		setSchemaType( ucase( listLast( DocPath, '.' ) ) );

		var documentContent = "";

		switch( getSchemaType() ){
			case "cfm":
				savecontent variable="documentContent" {
					include APath;
				}
				if( !isJSON( trim( documentContent ) ) ) throwInvalidJSONException( documentContent );

				documentContent = serializeJSON( trim( documentContent ) );

				break;

			case "yaml":
			case "yml":

				var YAMLLoader = jLoader.create( "org.yaml.snakeyaml.Yaml" );
				var IOFile = jLoader.create( "java.io.File" ).init( DocPath );
				var InputStream = jLoader.create( "java.io.FileInputStream" ).init( IOFile );

				documentContent = getUtils().toCF( YAMLLoader.load( InputStream ) );

				break;

			case "json":
				if( left( DocPath, 4 ) == 'http' ){
					var req = new http();
					req.setMethod( "GET" );
					req.setURL( DocPath );
					documentContent = req.send().getPrefix().filecontent;
				} else{
					documentContent = fileRead( DocPath );
				}

				if( !isJSON( documentContent ) ) throwInvalidJSONException( documentContent );

				documentContent = deSerializeJSON( documentContent );

				break;

			default:
				throw(
					type="SwaggerSDK.ParserException",
					message="SwaggerSDK does not support schema using the .#lcase(getSchemaType())# file extension."
				);
		}

		return parse( documentContent , XPath );
	}


	/**
	* Parses an API Document recursively
	*
	* @param APIDoc		The struct representation of the API Document
	* @param [XPath]	The XPath to zoom the parsed document to during recursion
	**/
	public function parse( required struct APIDoc, required string XPath="" ){
		setDocumentObject( getWirebox().getInstance( "OpenAPIDocument@SwaggerSDK" ).init( arguments.APIDoc, arguments.XPath) );

		parseDocumentInheritance( parseDocumentReferences( getDocumentObject().getDocument() ) );

		return this;
	}

	/**
	* Loads a linked hash map from a JSON file
	*
	* @param JSONData	The raw JSON string
	**/
	private function loadAsLinkedHashMap( required string JSONData ){

		var JSONFactory = jLoader.create("com.fasterxml.jackson.core.JsonFactory" );
		var Codec = jLoader.create( "com.fasterxml.jackson.core.ObjectCodec" );
		var CodecProxy = createObject("java", "coldfusion.runtime.java.JavaProxy" ).init( Codec );

		var Parser = JSONFactory.createParser( arguments.JSONData );
		var Mapper = jLoader.create( "java.util.Map" );
		var HashMap = structNew( "ordered" );

		HashMap.putAll( deSerializeJSON( JSONData ) );
	}

	/**
	* Parses API Document $ref notations recursively
	*
	* @param APIDoc		The struct representation of the API Document
	* @param [XPath]	The XPath to zoom the parsed document to during recursion
	**/
	public function parseDocumentReferences( required any DocItem ){

		if( isArray( DocItem ) ) {
			for( var i = 1; i <= arrayLen( DocItem ); i++){
				DocItem[ i ] = parseDocumentReferences( DocItem[ i ] );
			}
		} else if( isStruct( DocItem ) ) {

            //handle top-level values, if they exist
			if( structKeyExists( DocItem, "$ref" ) ) return fetchDocumentReference( DocItem[ "$ref" ] );

			for( var key in DocItem){

                if (
					isStruct( DocItem[ key ] )
					&&
					structKeyExists( DocItem[ key ], "$ref" )
				) {

					DocItem[ key ] = fetchDocumentReference( DocItem[ key ][ "$ref" ] );

				} else if( isStruct( DocItem[ key ] ) ||  isArray( DocItem[ key ] ) ){

					DocItem[ key ] = parseDocumentReferences( DocItem[ key ] );

				}

			}
		}

		return DocItem;

	}


    /**
	* Parses API Document $allOf notations recursively
	*
	* @param APIDoc		The struct representation of the API Document
	* @param [XPath]	The XPath to zoom the parsed document to during recursion
	**/
	public function parseDocumentInheritance( required any DocItem ){

        if( isArray( DocItem ) ) {
            for( var i = 1; i <= arrayLen( DocItem ); i++){
				DocItem[ i ] = parseDocumentInheritance( DocItem[ i ] );
			}
		} else if( isStruct( DocItem ) ) {

			var compositionKeys = [ "$extend", "$allOf", "$oneOf" ]; // deprecated: $allOf, $oneOf

			for( var composition in compositionKeys ){

				// handle top-level extension
				if(
					structKeyExists( DocItem, composition ) &&
					isArray( DocItem[ composition ] )
				) {
					return extendObject( DocItem[ composition ] );
				}

				for( var key in DocItem){

					if (
						isStruct( DocItem[ key ] ) &&
						structKeyExists( DocItem[ key ], composition ) &&
						isArray( DocItem[ key ][ composition ] )
					) {
						DocItem[ key ] = parseDocumentReferences( extendObject( DocItem[ key ][ composition ] ) );
					} else if( isStruct( DocItem[ key ] ) ||  isArray( DocItem[ key ] ) ){
						DocItem[ key ] = parseDocumentInheritance( parseDocumentReferences( DocItem[ key ] ) );
					}

				}
			}

		}

		return DocItem;

	}


    /**
     * Extends schema definitions based on the passed array of schema objects
     * Note: Ignores CFML objects (non-structs) because sometimes the parser gets passed in here for some reason
     *
     * @objects
     */
    function extendObject( array objects ) {
        var output = {};
        objects.each( function( item, index ) {
            if ( isStruct( item ) ) {
			
				// If `item` is an instance of Parser, we need to flattin it to a CFML struct
                if ( findNoCase( "Parser", getMetaData( item ).name ) ) {
                    item = item.getNormalizedDocument();
                }
			
                item.each( function( key, value ) {

                    if (
                        output.keyExists( key ) &&
                        isStruct( output[ key ] )
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

		//resolve internal refrences before looking for externals
		if( left( $ref, 1 ) == chr( 35 )){
			var FilePath = "";
			var XPath = right( $ref, len( $ref ) - 1 );
		} else {
			var refArray = listToArray( $ref, chr( 35 ) );
			var FilePath = refArray[ 1 ];
			if( arrayLen( refArray ) > 1 ) {
				var XPath = refArray[ 2 ];
				if( left( XPath, 1 ) == '/' ){
					XPath = right( XPath, len( XPath ) - 1 );
				}
			}
		}

		var ReferenceDocument = {};

		try{

			//Files receive a parser reference
			if( left( FilePath, 4 ) == 'http'  ){

				ReferenceDocument = Wirebox.getInstance( "OpenAPIParser@SwaggerSDK" ).init(  $ref );

			} else if( len( FilePath ) && fileExists( getDirectoryFromPath( getBaseDocumentPath() ) &  FilePath )){

                ReferenceDocument = Wirebox.getInstance( "OpenAPIParser@SwaggerSDK" ).init(  getDirectoryFromPath( getBaseDocumentPath() ) & $ref );

			} else if( len( FilePath ) && fileExists( expandPath( FilePath ) ) ) {

				ReferenceDocument = Wirebox.getInstance( "OpenAPIParser@SwaggerSDK" ).init(  expandPath( FilePath ) & ( !isNull( xPath ) ? "##" & xPath : "" ) );

			} else if( len( FilePath ) && !fileExists( getDirectoryFromPath( getBaseDocumentPath() ) &  FilePath )) {

				throw( type="SwaggerSDK.ParserException", message="File #( getDirectoryFromPath( getBaseDocumentPath() ) &  FilePath )# does not exist" );

			} else if( !isNull( XPath )  && len( XPath ) ) {

				ReferenceDocument = getInternalXPath( XPath );

			} else {

				throw( type="SwaggerSDK.ParserException", message="The $ref #$ref# could not be resolved as either an internal or external reference");

			}

		} catch( any e ){

            // if this is a known exception or occured via recursion, rethrow the exception so the user knows which JSON file triggered it
			if ( listFindNoCase( "SwaggerSDK.ParserException,CBSwagger.InvalidReferenceDocumentException", e.type ) ) {
                rethrow;
            }
            
            throw(
				type="CBSwagger.InvalidReferenceDocumentException",
				message="The $ref file pointer of #$ref# could not be loaded and parsed as a valid object.  If your $ref file content is an array, please nest the array within an object as a named key."
			);

		}

        return ReferenceDocument;
	}

	/**
	* Multi-use error throw
	* @param InvalidContent 	The content which cause the exception
	**/
	private function throwInvalidJSONException( required string InvalidContent ){

		throw( type="SwaggerSDK.ParserException", message="The API Document Provided: #getBaseDocumentPath()# could not be converted to valid JSON" );

	}

}
