/**
 * Copyright Ortus Solutions, Corp, All rights reserved
 * www.ortussolutions.com
 * ---
 * Open API Document Object
 */
component name="OpenAPIDocument" accessors="true" {

	property name="RootDocument";
	property name="Document";
	property name="XPath";

	// DI
	property name="wirebox" inject="wirebox";
	property name="jLoader" inject="loader@cbjavaloader";

	/**
	 * Constructor
	 *
	 * @param Doc	The document representation
	 * @param XPath	The XPath of the document to zoom this Document object to
	 **/
	Document function init( required struct Doc, required string XPath="" ){

		// Scope the root Document to handle internal inheritance $refs
		setRootDocument( arguments.Doc );

		// Set the working document which will be returned when normalized
		setDocument( arguments.Doc );

		// Zoom if requested
		if( len( arguments.XPath ) ){
			arguments.XPath = arrayToList( listToArray( arguments.XPath, "/" ), "." );
			this
				.setXPath( arguments.XPath )
				.zoomToXPath();
		}

		return this;
	}

	/**
	* Convenience methot for setting the XPath of the Document
	*
	* @param XPath	The XPath to zoom the parsed document to during recursion
	**/
	Document function xPath( required string XPath ){
		this.setXPath( arguments.XPath );
		return this;
	}

	/**
	* Zooms this Document instance to the XPath
	**/
	Document function zoomToXPath(){
		if( isNull( getXPath() ) ) return;

		setDocument( locate( getXPath() ) );

		return this;
	}

	/**
	 * Convenience method to return a flattened struct of the Document instance
	 **/
	function asStruct(){
		return getNormalizedDocument();
	}

	/**
	 * Convenience method to return a YAML string of the normalized document
	 **/
	function asYAML(){
		return variables.jLoader
			.create( "org.yaml.snakeyaml.Yaml" )
			.dump( getNormalizedDocument() );
	}

	/**
	 * Convenience method to return a JSON representation of the normalized document
	 **/
	function asJSON(){
		return serializeJSON( getNormalizedDocument() );
	}

	/**
	 * Normalizes the document recursively to provide a flattened representation
	 *
	 * @param APIDoc 	The document to normalized.  Defaults to the entity document
	 **/
	function getNormalizedDocument( any APIDoc=this.getDocument() ){
		if( isArray( arguments.APIDoc ) ){
			 return arrayMap( arguments.APIDoc, function( item ) {
                return getNormalizedDocument( item );
             } );
        } else if ( isObject( arguments.APIDoc ) && findNoCase( "Parser", getMetaData( arguments.APIDoc ).name ) ) {
            if ( !structKeyExists( arguments.APIDoc, "getDocumentObject" )  ) {
                throwForeignObjectTypeException( arguments.APIDoc );
                throw(
                    type = "SwaggerSDK.NormalizationException",
                    message = "SwaggerSDK doesn't know what do with an object of type #getMetaData( arguments.APIDoc ).name#."
                );
            }

            return arguments.APIDoc.getDocumentObject().getNormalizedDocument();
        } else if ( isStruct( arguments.APIDoc ) ) {
            return structMap( arguments.APIDoc, function( key, value ) {
				// allow explicit nulls in sample docs to pass through
                return !isNull( value ) ? getNormalizedDocument( value ) : javacast( "null", 0 );
            } );
        }

        return arguments.APIDoc;
	}

	/**
	 * Helper function to locate deeply nested document items
	 *
	 * @param key the key to locate
	 * @return any the value of the key or a `$ref` object if the key is not found
	 * @usage locate('key.subkey.subsubkey.waydowndeepsubkey')
	 **/
	any function locate( string key ){
		var rootDocument = this.getRootDocument();

		if( structKeyExists( rootDocument, arguments.key ) ){
			return rootDocument[ arguments.key ];
		} else if( isDefined( 'rootDocument.#arguments.key#' ) ){
				return evaluate( 'rootDocument.#arguments.key#' );
		} else {
			return { "$ref" : "##/#arrayToList( listToArray( arguments.key, "." ), "/" )#"};
		}
	}

	/********************************************************************************/
	/*  PRIVATE FUNCTIONS
	/********************************************************************************/

	/**
	* Throws a foreign object type exception if detected when normalizing a document
	* @param UnKnownObject 		The foreign object detected
	**/
	private function throwForeignObjectTypeException( required any UnKnownObject ){
		throw(
			type="SwaggerSDK.ForeignObjectException",
			message="SwaggerSDK doesn't know what do with an object of type #getMetaData( UnKnownObject ).name#."
		);
	}

}
