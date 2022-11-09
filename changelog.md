# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

----
## [3.0.0] => Unreleased
### Fixed

* [cbSwagger #35](https://github.com/coldbox-modules/cbSwagger/issues/35) Fixed an issue where inheritance `$ref` pointers on a Zoomed document could not be found

### Added

* [cbSwagger #35](https://github.com/coldbox-modules/cbSwagger/issues/35) Added support for [polymorphic inheritance expansion](https://swagger.io/docs/specification/data-models/inheritance-and-polymorphism/) ( e.g. `$allOf` )

### Changed

* Removed assignment of `x-resourceId` keys used by Relax from Swagger SDK parsing. [cbSwagger #20](https://github.com/coldbox-modules/cbSwagger/issues/20), [cbSwagger #27](https://github.com/coldbox-modules/cbSwagger/issues/27)
* Removed support for Adobe Coldfusion 2016

## [2.1.0] => 2021-NOV-12

### Added

* Adobe 2021 Support
* Migration to github actions
* Allow for `refs` that contain `refs` thanks to @elpete
* Handle `refs` in arrays thanks to @elpete
* Removed entrypoint for cleanup of routes
* Remove empty `externalDocs` object as the default value.  Many validation and linting tools do not allow empty strings as valid urls or descriptions. Additionally, `externalDocs` is hardly used. Users may add it back in if they would like, but the default will be to omit it.

### Fixed

* Allows explicit nulls in samples to pass through

----

## [2.0.0] => 2019-SEP-02

* Open API 3.02 support instead of swagger
* New template layout
* Engine removals: lucee4.5, ACF10, ACF11
* Upgraded jackson-core to latest v2.9.9
* Upgraded snakeyaml to latest v1.24
* Added more tests
* Added ability to chain methods on all methods that where void before.
* `document.asYAML()` is not fully implemented so you can convert the document to yaml.
* Upgraded `createLinkedHashMap()` to use new ACF `structNew( "ordered" )` instead.

----

## [1.0.4] => 2017-NOV-02

* Adds security definitions to default template

----

## [1.0.2] => 2017-FEB-19

* Adobe Coldfusion compatibility updates

----

## [1.0.1] => 2016-DEC-12

* Adds $ref support for relative and remote ( http[s] )

----

## [1.0.0] => 2016-OCT-02

* Initial Module Release
  