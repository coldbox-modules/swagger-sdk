/**
 * My BDD Test
 */
component extends="tests.resources.BaseOpenAPISpec" {

	public function beforeAll(){
		super.beforeAll();

		variables.testJSONAPIDIrectory = expandPath( "/tests/resources/coldboxRest" );

		expect( directoryExists( testJSONAPIDIrectory ) ).toBeTrue(
			"The test JSON API directory does not exist. Could not continue."
		);

		expect( fileExists( testJSONAPIDIrectory & "/" & listLast( testJSONAPIDIrectory, "/\" ) & ".json" ) ).toBeTrue(
			"A JSON API file named #listLast( testJSONAPIDIrectory, "/\" ) & ".json"# does not exist in the #testJSONAPIDIrectory# directory.  Could not continue."
		);

		VARIABLES.testJSONFile = testJSONAPIDIrectory & "/" & listLast( testJSONAPIDIrectory, "/\" ) & ".json";
	}

	struct function parseApiDoc(){
		var parser    = getInstance( "OpenAPIParser@SwaggerSDK" ).init( VARIABLES.TestJSONFile );
		var parserDoc = parser.getDocumentObject();
		return parserDoc.getNormalizedDocument();
	}

	/*********************************** BDD SUITES ***********************************/

	function run(){
		// all your suites go here.
		describe( "Performs and tests common Coldbox Restful app functionality", function(){
			beforeEach( function( currentSpec ){
				setup();
			} );

			it( "Can parse the apiDoc", function(){
				var apiDoc = parseApiDoc();

				// it can have multiple servers
				expect( apiDoc ).toHaveKey( "servers" );
				expect( apiDoc.servers ).toBeArray();
				expect( apiDoc.servers.len() ).toBe( 2 );

				// it has multiple paths produced by $extend
				expect( apiDoc ).toHaveKey( "paths" );
				expect( apiDoc.paths ).toHaveKey( "/users" );
				expect( apiDoc.paths ).toHaveKey( "/posts" );

				// schema: expectations
				expect( apiDoc.components ).toHaveKey( "schemas" );
				expect( apiDoc.components.schemas ).toHaveKey( "Pagination" );
				expect( apiDoc.components.schemas ).toHaveKey( "User" );
				expect( apiDoc.components.schemas ).toHaveKey( "Post" );
				expect( apiDoc.components.schemas ).toHaveKey( "Media" );

				// schema inherited objects via `allOf`
				var childObjects = [ "BookMedia", "MusicMedia" ];

				for ( var item in ChildObjects ) {
					expect( apiDoc.components.schemas ).toHaveKey( item );
					expect( apiDoc.components.schemas[ item ] ).toHaveKey( "allOf" );
					expect( apiDoc.components.schemas[ item ].allOf ).toBeArray();
					expect( apiDoc.components.schemas[ item ].allOf[ 1 ] ).toBeStruct();
					expect( apiDoc.components.schemas[ item ].allOf[ 1 ] ).toHaveKey( "$ref" );
					expect( apiDoc.components.schemas[ item ].allOf[ 1 ][ "$ref" ] ).toBe( "##/components/schemas/Media" );
				}

				// users.index intentionally doesn't use components/schema. Check for existence of $ref object
				expect( apiDoc.paths[ "/users" ] ).toHaveKey( "get" );
				expect( apiDoc.paths[ "/users" ].get ).toHaveKey( "responses" );
				expect( apiDoc.paths[ "/users" ].get.responses ).toHaveKey( "200" );
				expect( apiDoc.paths[ "/users" ].get.responses[ "200" ] ).toHaveKey( "content" );
				expect( apiDoc.paths[ "/users" ].get.responses[ "200" ].content ).toHaveKey( "application/json" );
				expect( apiDoc.paths[ "/users" ].get.responses[ "200" ].content[ "application/json" ] ).toHaveKey( "schema" );
				expect( apiDoc.paths[ "/users" ].get.responses[ "200" ].content[ "application/json" ].schema ).toHaveKey( "properties" );
				expect(
					apiDoc.paths[ "/users" ].get.responses[ "200" ].content[ "application/json" ].schema.properties
				).toHaveKey( "data" );
				expect(
					apiDoc.paths[ "/users" ].get.responses[ "200" ].content[ "application/json" ].schema.properties.data
				).toHaveKey( "properties" );
				expect(
					apiDoc.paths[ "/users" ].get.responses[ "200" ].content[ "application/json" ].schema.properties.data.properties
				).toHaveKey( "results" );
				expect(
					apiDoc.paths[ "/users" ].get.responses[ "200" ].content[ "application/json" ].schema.properties.data.properties
				).toHaveKey( "pagination" );
				expect(
					apiDoc.paths[ "/users" ].get.responses[ "200" ].content[ "application/json" ].schema.properties.data.properties.results
				).toHaveKey( "items" );
				expect(
					apiDoc.paths[ "/users" ].get.responses[ "200" ].content[ "application/json" ].schema.properties.data.properties.results.items
				).toHaveKey( "properties" );

				var expectedKeys = [ "id", "firstName", "lastName" ];

				for ( var item in expectedKeys ) {
					expect(
						apiDoc.paths[ "/users" ].get.responses[ "200" ].content[ "application/json" ].schema.properties.data.properties.results.items.properties
					).toHaveKey( item );
				}

				// expect the requestBody reference to have one pound sign
				expect( apiDoc.paths[ "/posts" ].post.requestBody ).toHaveKey( "$ref" );
				expect(
					left(
						apiDoc.paths[ "/posts" ].post.requestBody[ "$ref" ],
						2
					)
				).toBe( "#chr( 35 )#/" );
			} );
		} );
	}

}
