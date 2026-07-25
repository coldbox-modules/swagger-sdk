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

			it( "loads YAML via SnakeYAML when BoxLang yamlDeserialize is not available", function(){
				var parser = prepareMock( getInstance( "OpenAPIParser@SwaggerSDK" ) );
				makePublic( parser, "loadYamlFile" );
				parser.$( "canUseBoxlangYamlBifs" ).$results( false );

				var content = parser.loadYamlFile( VARIABLES.TestYAMLFile );
				expect( content ).toBeStruct();
				expect( content ).toHaveKey( "openapi" );
			} );

			it( "resolves relative ./schema $refs without hanging when the same responses file is reused", function(){
				var docPath = expandPath( "/tests/resources/refSafety/shared/doc.yml" );
				expect( fileExists( docPath ) ).toBeTrue();

				var parser = getInstance( "OpenAPIParser@SwaggerSDK" ).init( docPath );
				runParserTypeChecks( parser );

				var normalized = parser.getNormalizedDocument();
				expect( normalized ).toHaveKey( "paths" );
				expect( normalized.paths ).toHaveKey( "/items" );
				expect( normalized.paths ).toHaveKey( "/items/{id}" );

				var itemsGet = normalized.paths[ "/items" ].get;
				expect( itemsGet.responses ).toHaveKey( "200" );
				expect( itemsGet.responses[ "200" ].content[ "application/json" ].schema ).toHaveKey( "properties" );
				expect( itemsGet.responses[ "200" ].content[ "application/json" ].schema.properties ).toHaveKey( "id" );

				// Shared error schema should be inlined for both 400 and 500
				expect( itemsGet.responses[ "400" ].content[ "application/json" ].schema.properties ).toHaveKey(
					"error"
				);
				expect( itemsGet.responses[ "500" ].content[ "application/json" ].schema.properties ).toHaveKey(
					"error"
				);

				// Reused responses.yml on a second path must also resolve (cache path)
				expect(
					normalized.paths[ "/items/{id}" ].get.responses[ "200" ].content[ "application/json" ].schema.properties
				).toHaveKey( "name" );
			} );

			it( "does not recurse forever when YAML files contain circular $refs", function(){
				var docPath = expandPath( "/tests/resources/refSafety/cycles/doc.yml" );
				expect( fileExists( docPath ) ).toBeTrue();

				var parser     = getInstance( "OpenAPIParser@SwaggerSDK" ).init( docPath );
				var normalized = parser.getNormalizedDocument();

				expect( normalized ).toHaveKey( "paths" );
				expect( normalized.paths ).toHaveKey( "/cycle" );
				var schema = normalized.paths[ "/cycle" ].get.responses[ "200" ].content[ "application/json" ].schema;
				expect( schema ).toBeStruct();
				// Either fully inlined properties, or a preserved cycle marker $ref — must not hang either way
				expect( structKeyExists( schema, "properties" ) || structKeyExists( schema, "$ref" ) ).toBeTrue();
			} );

			it( "resolves absolute filesystem $ref paths without joining them onto the base document directory", function(){
				var fixtureDir = expandPath( "/tests/resources/refSafety" );
				var schemaPath = fixtureDir & "/absoluteSchema.yml";
				var docPath    = fixtureDir & "/absoluteDoc.yml";

				fileWrite(
					docPath,
					"openapi: ""3.0.2""
info:
  title: Absolute ref fixture
  version: ""1.0.0""
paths:
  /abs:
    get:
      responses:
        200:
          description: OK
          content:
            application/json:
              schema:
                $ref: ""#schemaPath#""
"
				);

				try {
					var parser     = getInstance( "OpenAPIParser@SwaggerSDK" ).init( docPath );
					var normalized = parser.getNormalizedDocument();
					var schema     = normalized.paths[ "/abs" ].get.responses[ "200" ].content[ "application/json" ].schema;
					expect( schema ).toHaveKey( "properties" );
					expect( schema.properties ).toHaveKey( "ok" );
				} finally {
					if ( fileExists( docPath ) ) {
						fileDelete( docPath );
					}
				}
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
