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
				expect( DocumentObject ).toBeComponent();
				expect( DocumentObject ).toHaveKey( "getDocument" );

				//test that path items have resource IDs
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
		} );
	}
	
}
