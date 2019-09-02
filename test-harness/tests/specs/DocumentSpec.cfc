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
				var instanceDoc = DocumentObject.getDocument();

				for( var pathKey in instanceDoc[ "paths" ] ){

					expect( instanceDoc[ "paths" ][ pathKey ] ).toHaveKey( "x-resourceId" );

					if( structKeyExists( instanceDoc[ "paths" ][ pathKey ], "methods" ) ){
						for( var methodKey in instanceDoc[ "paths" ][ pathKey ][ "methods" ] ){
							expect( instanceDoc[ "paths" ][ pathKey ][ "methods" ][ methodKey ] ).toHaveKey( "x-resourceId" );
						}
					}
				}

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
	}

}
