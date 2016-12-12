<cfscript>
/**
* Mixin utility to handle the way older versions of ACF handle the init method when creating a java object
**/
function createLinkedHashMap(){
	if( !isNull( VARIABLES ) && structKeyExists( VARIABLES, "Controller" ) ){
		var controller = VARIABLES.controller;
	} else if( structKeyExists( APPLICATION, "cbController" ) ) {
		var controller = application.cbController;
	} else {
		throw( "This method must be called from within the Coldbox request or application context" );
	}

	if( !isNull(VARIABLES) && structKeyExists( VARIABLES, "jLoader" ) ){
		var HashMap = VARIABLES.jLoader.create( "java", "java.util.LinkedHashMap" );
	} else {
		var HashMap = createObject( "java", "java.util.LinkedHashMap" );
	}

	switch( controller.getCFMLEngine().getEngine() ){
		case "ADOBE":
			return HashMap.init();
			break;
		default:
			return HashMap;
	}
}	
</cfscript>
