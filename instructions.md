##See These Other Swagger/OpenAPI-aware Coldbox Modules

* [Relax](https://www.forgebox.io/view/relax)
* [cbSwagger](https://www.forgebox.io/view/cbswagger)


##Install Swaggger SDK ( via Commandbox )

`box install swagger-sdk`

##Usage

This SDK allows for creation, parsing, and normalization of OpenAPI documentation.  

###Parse a Swagger JSON or YML file:

```
var APIDoc = Wirebox.getInstance( "OpenAPIParser@SwaggerSDK" ).init( DocumentPathOrURL );
```

This returns the parsed document object, which can be fully normalized ( e.g. $ref attributes are loaded and normalized within the document ) with `APIDoc.getNormalizedDocument()`

You may also export the normalized document object to JSON (`APIDoc.asJSON()`), YAML (`APIDoc.asYAML()`), or as Struct++ (`APIDoc.asYAML()`)

++Note: in order to maintain order, the struct format used is a Java.util.LinkedHashmap.  In order to access struct keys you will need to use braces ( e.g. = `APIDoc[ "info" ][ "title" ]` )


See the APIDocs for additional information on methods and functions available in the SDK

