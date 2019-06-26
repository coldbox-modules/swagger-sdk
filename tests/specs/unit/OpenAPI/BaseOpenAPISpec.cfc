component extends="testbox.system.BaseSpec" name="BaseOpenAPISpec" {
	property name="TestJSONAPIDirectory";
	property name="TestYAMLAPIDirectory";
	property name="TestJSONFile";
	property name="TestYAMLFile";
	property name="Wirebox" inject="wirebox";

	this.loadColdbox = false;
	
	public function beforeAll(){
		var File = createObject("java", "java.io.File");
		VARIABLES.TestJSONAPIDIrectory = expandPath( "/tests/resources/petstore" );
		VARIABLES.TestYAMLAPIDIrectory = expandPath( "/tests/resources/petstore" );
		expect( APPLICATION ).toHaveKey( "wirebox", "Wirebox is required to perform this test spec.  Could not continue" );
		APPLICATION.wirebox.autowire( this );
		expect( isNull( Wirebox ) ).toBeFalse( "Autowiring failed.  Tests could not continue." );
		
		expect( directoryExists( TestJSONAPIDirectory ) ).toBeTrue( "The test JSON API directory does not exist. Could not continue." );
		expect( fileExists( TestJSONAPIDirectory & File.separator & listLast(TestJSONAPIDirectory,File.separator) & ".json" ) ).toBeTrue( "A JSON API file named #listLast(TestJSONAPIDirectory,File.separator) & ".json"# does not exist in the #TestJSONAPIDirectory# directory.  Could not continue." );
		VARIABLES.TestJSONFile = TestJSONAPIDirectory & File.separator & listLast(TestJSONAPIDirectory,File.separator) & ".json";

		expect( fileExists( TestYAMLAPIDirectory & File.separator & listLast(TestYAMLAPIDirectory,File.separator) & ".yaml" ) ).toBeTrue( "A YML API file named #listLast(TestYAMLAPIDirectory,File.separator) & ".yaml"# does not exist in the #TestYAMLAPIDirectory# directory.  Could not continue." );
		VARIABLES.TestYAMLFile = TestYAMLAPIDirectory & File.separator & listLast(TestYAMLAPIDirectory,File.separator) & ".yaml";

	};

	public function afterAll(){
		
	};

}