component extends="coldbox.system.testing.BaseTestCase" appmapping="/root" {

	property name="TestJSONAPIDirectory";
	property name="TestYAMLAPIDirectory";
	property name="TestJSONFile";
	property name="TestYAMLFile";

	this.loadColdbox   = true;
	this.unloadColdBox = false;

	public function beforeAll(){
		super.beforeAll();

		VARIABLES.testJSONAPIDIrectory = expandPath( "/tests/resources/petstore" );
		VARIABLES.testYAMLAPIDIrectory = expandPath( "/tests/resources/petstore" );


		expect( directoryExists( TestJSONAPIDirectory ) ).toBeTrue(
			"The test JSON API directory does not exist. Could not continue."
		);

		expect( fileExists( TestJSONAPIDirectory & "/" & listLast( TestJSONAPIDirectory, "/\" ) & ".json" ) ).toBeTrue(
			"A JSON API file named #listLast( TestJSONAPIDirectory, "/\" ) & ".json"# does not exist in the #TestJSONAPIDirectory# directory.  Could not continue."
		);

		VARIABLES.testJSONFile = TestJSONAPIDirectory & "/" & listLast( TestJSONAPIDirectory, "/\" ) & ".json";

		expect( fileExists( testYAMLAPIDirectory & "/" & listLast( testYAMLAPIDirectory, "/\" ) & ".yaml" ) ).toBeTrue(
			"A YML API file named #listLast( testYAMLAPIDirectory, "/\" ) & ".yaml"# does not exist in the #testYAMLAPIDirectory# directory.  Could not continue."
		);

		VARIABLES.testYAMLFile = testYAMLAPIDirectory & "/" & listLast( TestYAMLAPIDirectory, "/\" ) & ".yaml";
	}

	public function afterAll(){
		super.afterAll();
	}

	function run(){
		throw( "Must be implemented in a concrete spec" );
	}

}
