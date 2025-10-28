component extends="tests.resources.BaseOpenAPISpec" {

	function run(){
		describe( "Performs and tests general OpenAPIParser operations", function(){
			beforeEach( function(){
				setup();
			} );

			it( "Tests the ability instantiate the parser using a JSON file", function(){
				var JSONParser = getInstance( "OpenAPIParser@SwaggerSDK" ).init( VARIABLES.TestJSONFile );
				runParserTypeChecks( JSONParser );
				runParserRecursionTests( JSONParser, true );
			} );

			it( "Tests the ability instantiate the parser using a YAML file", function(){
				var YAMLParser = getInstance( "OpenAPIParser@SwaggerSDK" ).init( VARIABLES.TestYAMLFile );
				runParserTypeChecks( YAMLParser );
				runParserRecursionTests( YAMLParser );
			} );
		} );
	}

	function runParserTypeChecks( required Parser ){
		// Note: We can"t the type tests because ACF and Lucee don"t read the metadata the same way
		expect( ARGUMENTS.Parser ).toBeInstanceOf( "Parser" );
		expect( ARGUMENTS.Parser ).toHaveKey( "getDocumentObject" );
		expect( ARGUMENTS.Parser ).toHaveKey( "getSchemaType" );
		expect( ARGUMENTS.Parser.getSchemaType() ).toBeString();
		expect( ARGUMENTS.Parser ).toHaveKey( "getBaseDocumentPath" );
		expect( ARGUMENTS.Parser.getBaseDocumentPath() ).toBeString();
	}


	function runParserRecursionTests(
		required Parser,
		required boolean testObjects = false
	){
		if ( arguments.testObjects ) {
			var ParserDoc = arguments.Parser.getDocumentObject();
			expect( ParserDoc ).toBeInstanceOf( "Document" );
			expect( ParserDoc ).toHaveKey( "getDocument" );
			var APIDoc = ParserDoc.getDocument();
			expect( APIDoc ).toBeStruct();
			expect( APIDoc ).toHaveKey( "paths" );
			expect( APIDoc.paths ).toBeStruct();
			expect( APIDoc.paths ).toHaveKey( "/pets" );
		}

		var NormalizedDocument = arguments.Parser.getNormalizedDocument();

		expect( NormalizedDocument ).toBeStruct();
		expect( NormalizedDocument ).toHaveKey( "openapi" );
		expect( NormalizedDocument ).toHaveKey( "servers" );
		expect( NormalizedDocument ).toHaveKey( "info" );

		if ( arguments.Parser.getSchemaType() == "YAML" ) {
			expect( NormalizedDocument ).toHaveKey( "components" );
		}

		expect( NormalizedDocument ).toHaveKey( "paths" );

		expect( NormalizedDocument.paths ).toHaveKey( "/pets" );
		expect( NormalizedDocument.paths[ "/pets" ] ).toBeStruct();
		expect( NormalizedDocument.paths[ "/pets" ] ).toHaveKey( "get" );
		expect( NormalizedDocument.paths[ "/pets" ][ "get" ] ).toHaveKey( "summary" );
		expect( NormalizedDocument.paths[ "/pets" ][ "get" ] ).toHaveKey( "parameters" );
		expect( NormalizedDocument.paths[ "/pets" ][ "get" ] ).toHaveKey( "responses" );
		expect( NormalizedDocument.paths[ "/pets" ] ).toHaveKey( "post" );
		expect( NormalizedDocument.paths[ "/pets" ][ "post" ] ).toHaveKey( "summary" );
		expect( NormalizedDocument.paths[ "/pets" ][ "post" ] ).toHaveKey( "requestBody" );
		expect( NormalizedDocument.paths[ "/pets" ][ "post" ] ).toHaveKey( "responses" );

		expect( NormalizedDocument.paths ).toHaveKey( "/pet/{petId}" );
		expect( NormalizedDocument.paths[ "/pet/{petId}" ] ).toBeStruct();
		expect( NormalizedDocument.paths[ "/pet/{petId}" ] ).toHaveKey( "get" );
		expect( NormalizedDocument.paths[ "/pet/{petId}" ][ "get" ] ).toHaveKey( "summary" );
		expect( NormalizedDocument.paths[ "/pet/{petId}" ][ "get" ] ).toHaveKey( "parameters" );
		expect( NormalizedDocument.paths[ "/pet/{petId}" ][ "get" ] ).toHaveKey( "responses" );
		expect( NormalizedDocument.paths[ "/pet/{petId}" ] ).toHaveKey( "post" );
		expect( NormalizedDocument.paths[ "/pet/{petId}" ][ "post" ] ).toHaveKey( "summary" );
		expect( NormalizedDocument.paths[ "/pet/{petId}" ][ "post" ] ).toHaveKey( "parameters" );
		expect( NormalizedDocument.paths[ "/pet/{petId}" ][ "post" ] ).toHaveKey( "responses" );
		expect( NormalizedDocument.paths[ "/pet/{petId}" ] ).toHaveKey( "delete" );
		expect( NormalizedDocument.paths[ "/pet/{petId}" ][ "delete" ] ).toHaveKey( "summary" );
		expect( NormalizedDocument.paths[ "/pet/{petId}" ][ "delete" ] ).toHaveKey( "parameters" );
		expect( NormalizedDocument.paths[ "/pet/{petId}" ][ "delete" ] ).toHaveKey( "responses" );

		expect( arrayLen( structFindKey( NormalizedDocument, "$ref" ) ) ).toBe( 0 );
		expect( arrayLen( structFindKey( NormalizedDocument, "$extend" ) ) ).toBe( 0 );
	}

}
