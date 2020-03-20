/**
 * Copyright Ortus Solutions, Corp, All rights reserved
 * www.ortussolutions.com
 * ---
 * Open API Document Object
 */
component name="OpenAPIDocument" accessors="true" {

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

		setDocument( arguments.Doc );

		if( len( arguments.XPath ) ){
			this
				.setXPath( arguments.XPath )
				.zoomToXPath();
		}

		if( isStruct( arguments.Doc ) ){
			setResourceIds( arguments.Doc );
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
        }

        if ( isObject( arguments.APIDoc ) && findNoCase( "Parser", getMetaData( arguments.APIDoc ).name ) ) {
            if ( !structKeyExists( arguments.APIDoc, "getDocumentObject" )  ) {
                throwForeignObjectTypeException( arguments.APIDoc );
                throw(
                    type = "SwaggerSDK.NormalizationException",
                    message = "SwaggerSDK doesn't know what do with an object of type #getMetaData( arguments.APIDoc ).name#."
                );
            }

            return arguments.APIDoc.getDocumentObject().getNormalizedDocument();
        }

        if ( isStruct( arguments.APIDoc ) ) {
            return setResourceIds(
                structMap( arguments.APIDoc, function( key, value ) {
                    return getNormalizedDocument( value );
                } )
            );
        }

        return arguments.APIDoc;
	}

	/**
	 * Helper function to locate deeply nested document items
	 *
	 * @param key the key to locate
	 * @return any the value of the key or null if the key is not found
	 * @usage locate('key.subkey.subsubkey.waydowndeepsubkey')
	 **/
	any function locate( string key ){
		var document = this.getDocument();

		if( structKeyExists( document, arguments.key ) ){
			return document[ arguments.key ];
		} else {
			if( isDefined( 'document.#arguments.key#' ) ){
				return evaluate( 'document.#arguments.key#' );
			}
		}

		return document;
	}

	/********************************************************************************/
	/*  PRIVATE FUNCTIONS
	/********************************************************************************/

	/**
	 * Sets the resourceId extension of a document path
	 *
	 * @param resourceDoc	The document to parse for x-resourceId nodes
	 * @param hashPrefix		The prefix to use when hashing the x-resourceId value
	 **/
	private struct function setResourceIds(required struct resourceDoc, string hashPrefix="" ){
		var appendableNodes = [ "paths","get","post","put","patch","delete","head","option" ];

		for ( var resourceKey in appendableNodes ){

			if(  structKeyExists( arguments.resourceDoc, resourceKey ) && isStruct( arguments.resourceDoc[ resourceKey ] ) ){
				for( var pathKey in arguments.resourceDoc[ resourceKey ] ){
					if( !isStruct( arguments.resourceDoc[ resourceKey ][ pathKey ] ) ) continue;

					arguments.resourceDoc[ resourceKey ][ pathKey ].put( "x-resourceId", lcase( arguments.hashPrefix & hash( pathKey ) ) );

					//recurse, if necessary
					for( var subKey in arguments.resourceDoc[ resourceKey ][ pathKey ] ){
						if(
							arrayFindNoCase( appendableNodes, subKey )
							&&
							isStruct( arguments.resourceDoc[ resourceKey ][ pathKey ][ subKey ] )
						) {
							arguments.resourceDoc[ resourceKey ][ pathKey ][ subKey ].put( "x-resourceId", lcase( arguments.hashPrefix & hash( pathKey & subkey ) ) );
						}
					}
				}
			}
		}

        return arguments.resourceDoc;
	}

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
