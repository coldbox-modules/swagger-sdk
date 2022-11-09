/**
* My BDD Test
*/
component extends="BaseOpenAPISpec"{


/*********************************** BDD SUITES ***********************************/

	function run(){
		// all your suites go here.
		describe( "Performs and tests general OpenAPIParser operations" ,function(){

			beforeEach(function( currentSpec ){
				setup();
			});

			it( "Tests the ability instantiate the parser using a JSON file", function(){
				var JSONParser = getInstance( "OpenAPIParser@SwaggerSDK" ).init( VARIABLES.TestJSONFile );
				runParserTypeChecks( JSONParser );

				describe( "Performs recursion checks on parsed JSON document", function(){
					runParserRecursionTests( JSONParser, true );
				});

				describe( "Performs cross-conversion tests on the the parsed JSON document",function(){
					runParserConversionTests( JSONParser );
				});

			});

			it( "Tests the ability instantiate the parser using a YAML file", function(){
				var YAMLParser = getInstance( "OpenAPIParser@SwaggerSDK" ).init( VARIABLES.TestYAMLFile );
				runParserTypeChecks( YAMLParser );

				describe( "Performs recursion checks on parsed YAML document", function(){
					runParserRecursionTests( YAMLParser );
				});

			});

		});
	}

	function runParserTypeChecks( required Parser ){

		// Note: We can't the type tests because ACF and Lucee don't read the metadata the same way
		expect( ARGUMENTS.Parser ).toBeInstanceOf( "Parser" );
		expect( ARGUMENTS.Parser ).toHaveKey( "getDocumentObject" );
		//expect( ARGUMENTS.Parser.getDocumentObject() ).toBeInstanceOf( "SwaggerSDK.models.OpenAPI.Document" );
		expect( ARGUMENTS.Parser ).toHaveKey( "getSchemaType" );
		expect( ARGUMENTS.Parser.getSchemaType() ).toBeString();
		expect( ARGUMENTS.Parser ).toHaveKey( "getBaseDocumentPath" );
		expect( ARGUMENTS.Parser.getBaseDocumentPath() ).toBeString();

	}


	function runParserRecursionTests( required Parser, required boolean testObjects=false ){
		if( ARGUMENTS.testObjects ){

			it( "Tests for the recursive presence of OpenAPIDocument objects within Parser #Parser.getSchemaType()# document object" , function(){
				var ParserDoc = Parser.getDocumentObject();
				expect( ParserDoc ).toBeInstanceOf( "Document" );
				expect( ParserDoc ).toHaveKey( "getDocument" );
				var APIDoc = ParserDoc.getDocument();
				expect( APIDoc ).toBeStruct();
				expect( APIDoc ).toHaveKey( "paths" );
				expect( APIDoc.paths ).toBeInstanceOf( "Parser" );
				runParserTypeChecks( APIDoc.paths );
				var paths = APIDoc.paths.getDocumentObject().getNormalizedDocument();
				expect( paths ).toHaveKey( "/pets" );


			});

		}

		it( "Tests the ability to fully normalize the parsed #Parser.getSchemaType()# document" ,function(  ){
			var NormalizedDocument = Parser.getNormalizedDocument();

			expect( NormalizedDocument ).toBeStruct();
			expect( NormalizedDocument ).toHaveKey( "openapi" );
			expect( NormalizedDocument ).toHaveKey( "servers" );
			expect( NormalizedDocument ).toHaveKey( "info" );

			if(Parser.getSchemaType() eq "YAML")
				expect( NormalizedDocument ).toHaveKey( "components" );

			expect( NormalizedDocument ).toHaveKey( "paths" );

			expect( NormalizedDocument ).toHaveDeepKey( "/pets" );
			expect( NormalizedDocument.paths[ '/pets' ] ).toBeStruct();
			expect( NormalizedDocument.paths[ '/pets' ] ).toHaveDeepKey( "description" );
			expect( NormalizedDocument.paths[ '/pets' ] ).toHaveDeepKey( "parameters" );
			expect( NormalizedDocument.paths[ '/pets' ] ).toHaveDeepKey( "responses" );

			expect( NormalizedDocument ).toHaveDeepKey( "/pet/{petId}" );
			expect( NormalizedDocument.paths[ '/pet/{petId}' ] ).toBeStruct();
			expect( NormalizedDocument.paths[ '/pet/{petId}' ] ).toHaveDeepKey( "description" );
			expect( NormalizedDocument.paths[ '/pet/{petId}' ] ).toHaveDeepKey( "parameters" );
			expect( NormalizedDocument.paths[ '/pet/{petId}' ] ).toHaveDeepKey( "responses" );

			expect( arrayLen( structFindKey( NormalizedDocument, "$ref" ) ) ).toBe( 0 );
			expect( arrayLen( structFindKey( NormalizedDocument, "$allOf" ) ) ).toBe( 0 );

		});

	}

	function runParserConversionTests(required Parser){
		it( "Tests the parsers ability to perform cross-MIME type conversions on the parsed #Parser.getSchemaType()# document.",function(){

		});
	}

}
