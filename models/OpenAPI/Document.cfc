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
	Document function init(
		required struct Doc,
		required string XPath = ""
	){
		// Scope the root Document to handle internal inheritance $refs
		setRootDocument( arguments.Doc );

		// Set the working document which will be returned when normalized
		setDocument( arguments.Doc );

		// Zoom if requested
		if ( len( arguments.XPath ) ) {
			arguments.XPath = arrayToList(
				listToArray( arguments.XPath, "/" ),
				"."
			);
			this.setXPath( arguments.XPath ).zoomToXPath();
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
		if ( isNull( getXPath() ) ) return;

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
		if ( canUseBoxlangYamlBifs() ) {
			return yamlSerialize( getNormalizedDocument() );
		}
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
	function getNormalizedDocument( any APIDoc = this.getDocument() ){
		return normalizeDocument( arguments.APIDoc, {} );
	}

	/**
	 * Internal normalize with identity-based cycle detection (shared $ref graphs / Parser nests).
	 */
	private function normalizeDocument(
		required any APIDoc,
		required struct visited
	){
		if ( isArray( arguments.APIDoc ) ) {
			return arrayMap( arguments.APIDoc, function( item ){
				return normalizeDocument( item, visited );
			} );
		}

		if ( isObject( arguments.APIDoc ) ) {
			if ( isNestedOpenAPIParser( arguments.APIDoc ) ) {
				return arguments.APIDoc.getDocumentObject().getNormalizedDocument();
			}
			// Non-Parser objects (including Java types) pass through unchanged
			return arguments.APIDoc;
		}

		if ( isStruct( arguments.APIDoc ) ) {
			var visitKey = createObject( "java", "java.lang.System" ).identityHashCode( arguments.APIDoc );
			if ( structKeyExists( arguments.visited, visitKey ) ) {
				return arguments.APIDoc;
			}
			arguments.visited[ visitKey ] = true;

			return structMap( arguments.APIDoc, function( key, value ){
				// allow explicit nulls in sample docs to pass through
				return !isNull( value ) ? normalizeDocument( value, visited ) : javacast( "null", 0 );
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

		if ( structKeyExists( rootDocument, arguments.key ) ) {
			return rootDocument[ arguments.key ];
		} else if ( isDefined( "rootDocument.#arguments.key#" ) ) {
			return evaluate( "rootDocument.#arguments.key#" );
		} else {
			return {
				"$ref" : "##/#arrayToList(
					listToArray( arguments.key, "." ),
					"/"
				)#"
			};
		}
	}

	/********************************************************************************/
	/*  PRIVATE FUNCTIONS
	/********************************************************************************/

	/**
	 * Detect nested OpenAPIParser CFCs without getMetadata() (unsafe on Java / BoxLang proxies).
	 * Prefer isInstanceOf; duck-type on the normalization entry points as a fallback.
	 */
	private boolean function isNestedOpenAPIParser( required any value ){
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

		return structKeyExists( arguments.value, "getDocumentObject" )
			&& structKeyExists( arguments.value, "getNormalizedDocument" );
	}

	/**
	 * Prefer bx-yaml BIFs when present; otherwise use the shipped SnakeYAML jar.
	 */
	private boolean function canUseBoxlangYamlBifs(){
		if ( !server.keyExists( "boxlang" ) ) {
			return false;
		}
		var functions = getFunctionList();
		return structKeyExists( functions, "yamlDeserialize" )
			&& structKeyExists( functions, "yamlSerialize" );
	}

}
