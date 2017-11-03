/**
* Copyright Ortus Solutions, Corp, All rights reserved
* www.ortussolutions.com
* ---
* Open API Utilities
*/
component name="OpenAPIUtil" accessors="true" {
	
	public function init(){
		return this;
	}

	any function newTemplate(){
		//We need to use Linked Hashmaps to maintain struct order for serialization and deserialization
		var template = createLinkedHashMap();

			var templateDefaults  = [ 
			{"swagger"            : "2.0"},
			{
			  "info"              : {
			      "version"       : "",
			      "title"         : "",
			      "description"   : "",
			      "termsOfService": "",
			      "contact"       : createLinkedHashMap(),
			      "license"       : createLinkedHashMap()
			    }
			},
			{"host"               : ""},
			{"basePath"           : ""},
			{"schemes"            : []},
			{"consumes"           : ["application/json","multipart/form-data","application/x-www-form-urlencoded"]},
			{"produces"           : ["application/json"]},
			{"paths"              : createLinkedHashMap()},
			{"securityDefinitions": createLinkedHashMap()}

		];

		for( var templateDefault  in  templateDefaults ){
			template.putAll( templateDefault );
		}

		return template;
	}

	any function newMethod(){
		var method = createLinkedHashMap();
		var descMap = createLinkedHashMap();
		descMap.put( "description", "" );
		var methodDefaults   = [ 
			{"summary"    : ""},
			{"description": ""},
			{"operationId": ""},
			{"parameters" : []},
			{
				"responses"  : {
					"default": descMap
				}
			}
		];

		for( var methodDefault in methodDefaults ){
			method.putAll( methodDefault );
		}

		return method;
	}

	any function defaultMethods(){
		return [ "GET", "PUT", "POST" , "PATCH" , "DELETE" , "HEAD" ];
	}

	any function defaultSuccessResponses(){
		return [ 200, 200, 201, 200, 204, 204 ];
	}

	string function translatePath( required string URLPath ){
		var pathArray = listToArray( ARGUMENTS.URLPath, '/' );
		for( var i=1; i <= arrayLen( pathArray ); i++ ){
			if( left( pathArray[ i ], 1 ) == ':' ){
				pathArray[ i ] = "{" & replace( pathArray[ i ], ":", "" ) & "}";
			}
		}

		return "/" & arrayToList( pathArray, "/" );

	}


	/**
	* Converts a Java object to native CFML structure
	* @param Object Map  	The Java map object or array to be converted
	*/
	function toCF( Map ){

		if(isNull( Map )) return;
		
		//if we're in a loop iteration and the array item is simple, return it
		if(isSimpleValue( Map )) return Map;

		if(isArray( Map )){
			var cfObj = [];

			for(var obj in Map){
				arrayAppend(cfObj,toCF(obj));
			}
		
		} else {
		
			var cfObj = {};

			try{
				cfObj.putAll( Map );
			
			} catch (any e){
			
				return Map;
			}
			
			//loop our keys to ensure first-level items with sub-documents objects are converted
			for(var key in cfObj){
			
				if(!isNull(cfObj[key]) && ( isArray(cfObj[key]) || isStruct(cfObj[key]) ) ) cfObj[key] = toCF(cfObj[key]);
			
			}
		}

		return cfObj;
	}

}
