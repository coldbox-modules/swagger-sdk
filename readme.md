# Coldbox Swagger SDK
## The Swagger Software Development Kit for the Coldbox Platform

This module allows for software development using the Swagger/OpenAPI specification and utilizes the [v3.0 OpenAPI Specification]([https://github.com/OAI/OpenAPI-Specification/blob/OpenAPI.next/versions/3.0.md])

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



##LICENSE
Apache License, Version 2.0.

********************************************************************************
Copyright Since 2005 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
www.coldbox.org | www.luismajano.com | www.ortussolutions.com
********************************************************************************
####HONOR GOES TO GOD ABOVE ALL
Because of His grace, this project exists. If you don't like this, then don't read it, its not for you.

>"Therefore being justified by faith, we have peace with God through our Lord Jesus Christ:
By whom also we have access by faith into this grace wherein we stand, and rejoice in hope of the glory of God.
And not only so, but we glory in tribulations also: knowing that tribulation worketh patience;
And patience, experience; and experience, hope:
And hope maketh not ashamed; because the love of God is shed abroad in our hearts by the 
Holy Ghost which is given unto us. ." Romans 5:5

###THE DAILY BREAD
 > "I am the way, and the truth, and the life; no one comes to the Father, but by me (JESUS)" Jn 14:1-12