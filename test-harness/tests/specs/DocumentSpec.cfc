/**
* My BDD Test
*/
component extends="BaseOpenAPISpec"{

/*********************************** LIFE CYCLE Methods ***********************************/

	function beforeAll(){
		super.beforeAll();
		VARIABLES.testDocument = deserializeJSON( fileRead( VARIABLES.TestJSONFile ) );

	};

/*********************************** BDD SUITES ***********************************/

	function run(){

		describe( "Performs tests on document instantiation", function(){


			beforeEach(function( currentSpec ){
				setup();
			});

			it( "Tests the ability to instantiate an OpenAPI Document Object", function(  ){
				var DocumentObject = getInstance( "OpenAPIDocument@SwaggerSDK" ).init( VARIABLES.testDocument );

				expect( DocumentObject )
					.toBeComponent()
					.toHaveKey( "getDocument" );

				// test that path items have resource IDs
				var instanceDoc = DocumentObject.getNormalizedDocument();

				expect( instanceDoc ).toHaveKey( "openapi" )
								.toHaveKey( "info" )
								.toHaveKey( "paths" )
								.toHaveKey( "servers" )
								.toHaveKey( "tags" );
			} );


			it( "can be coverted to json", function(){
				var doc = getInstance( "OpenAPIDocument@SwaggerSDK" ).init( VARIABLES.testDocument );
				expect( doc.asJson() ).toBeJSON();
			});

			it( "can be coverted to struct", function(){
				var doc = getInstance( "OpenAPIDocument@SwaggerSDK" ).init( VARIABLES.testDocument );
				expect( doc.asStruct() ).toBeStruct();
			});

			it( "can be coverted to yaml", function(){
				var doc = getInstance( "OpenAPIDocument@SwaggerSDK" ).init( VARIABLES.testDocument );
				var outYaml = expandPath( "/tests/resources/petstore/test.yaml" );

				fileWrite( outYaml, doc.asYaml() );

				// Test it
				var outDoc = getInstance( "OpenAPIParser@SwaggerSDK" ).init( outYaml );

				// If we got here, it parsed correctly

			});

		} );

		describe( "Core functionality tests", function(){

			it( "Tests that an attempt to locate an invalid path with return a $ref object", function(){
				var DocumentObject = getInstance( "OpenAPIDocument@SwaggerSDK" ).init( VARIABLES.testDocument );

				expect( DocumentObject )
					.toBeComponent()
					.toHaveKey( "getDocument" );

				var invalidPath = DocumentObject.locate( "foo.bar" );
				expect( invalidPath ).toBeStruct().toHaveKey( "$ref" );
				expect( invalidPath[ "$ref" ] ).toBe( "##/foo/bar" );

			})
		})
	}

}
