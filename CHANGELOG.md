# Parse-Swift Changelog

### main
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.0.0...main)
* _Contributing to this repo? Add info about your change here to be included in next release_

__New features__
- Save child pointers and deep saving of objects ([#21](https://github.com/parse-community/Parse-Swift/pull/21)), thanks to [Corey Baker](https://github.com/cbaker6).
- Add Swift Package Index support ([#19](https://github.com/parse-community/Parse-Swift/pull/19)), thanks to [Corey Baker](https://github.com/cbaker6).
- Persist `ParseUser`, `ParseInstallation`, and default `ParseACL` to Keychain ([#19](https://github.com/parse-community/Parse-Swift/pull/19)), thanks to [Corey Baker](https://github.com/cbaker6).
- Add watchOS and tvOS builds to travis. Add codecov and jazzy docs ([#17](https://github.com/parse-community/Parse-Swift/pull/17)), thanks to [Corey Baker](https://github.com/cbaker6).
- Add unit tests for: APICommand, ParseObject, ParseUser. Mover result callbacks to result enum. ([#14](https://github.com/parse-community/Parse-Swift/pull/14)), thanks to [Corey Baker](https://github.com/cbaker6).
- Add PrimitiveObectStore protocol that extends Keychain Store. ([#13](https://github.com/parse-community/Parse-Swift/pull/13)), thanks to [Pranjal Satija](https://github.com/pranjalsatija).
- Add `AnyCodable` support ([#12](https://github.com/parse-community/Parse-Swift/pull/12)), thanks to [Corey Baker](https://github.com/cbaker6) and [Shawn Baek](https://github.com/ShawnBaek).
- Add Keychain storage ([#7](https://github.com/parse-community/Parse-Swift/pull/7)), thanks to [Florent Vilmart](https://github.com/flovilmart).
- Add `ParseError` ([#6](https://github.com/parse-community/Parse-Swift/pull/6)), thanks to [Florent Vilmart](https://github.com/flovilmart).
- Create Parse-Swift project and add Travis CI ([#1](https://github.com/parse-community/Parse-Swift/pull/1)), thanks to [Florent Vilmart](https://github.com/flovilmart).

__Improvements__
- Add tests for Parse pointers. ([#23](https://github.com/parse-community/Parse-Swift/pull/23)), thanks to [Corey Baker](https://github.com/cbaker6).
- Add a new ParseEncoder from Swift 5.3 open-source JSON encoder. ([#21](https://github.com/parse-community/Parse-Swift/pull/21)), thanks to [Corey Baker](https://github.com/cbaker6).
- Full support of `ParseGeopoint` and improve querying ([#21](https://github.com/parse-community/Parse-Swift/pull/21)), thanks to [Corey Baker](https://github.com/cbaker6).
- Switch repo from `master` to `main` branch ([#20](https://github.com/parse-community/Parse-Swift/pull/20)), thanks to [Corey Baker](https://github.com/cbaker6).
- Added documentation to the code ([#19](https://github.com/parse-community/Parse-Swift/pull/19)), thanks to [Corey Baker](https://github.com/cbaker6).
- Switch from Travis CI to Github Actions ([#18](https://github.com/parse-community/Parse-Swift/pull/18)), thanks to [Corey Baker](https://github.com/cbaker6).
- Improved async networking calls. ([#15](https://github.com/parse-community/Parse-Swift/pull/15)), thanks to [Corey Baker](https://github.com/cbaker6).
- Rename and restructure project ([#13](https://github.com/parse-community/Parse-Swift/pull/13)), thanks to [Pranjal Satija](https://github.com/pranjalsatija).
- Update to Swift 5.0 ([#12](https://github.com/parse-community/Parse-Swift/pull/12)), thanks to [Corey Baker](https://github.com/cbaker6).
- Add documentation for SPM, Cocoapods, Carthage, CONTRIBUTING.md, and README ([#10](https://github.com/parse-community/Parse-Swift/pull/10)), thanks to [Tom Fox](https://github.com/TomWFox).
- Remove RESTCommand and add API.Command ([#6](https://github.com/parse-community/Parse-Swift/pull/6)), thanks to [Florent Vilmart](https://github.com/flovilmart).

__Fixes__
- Fixed bugs in ParseACL and bump minimum OS support to `.iOS(.v11), .macOS(.v10_13), .tvOS(.v11), .watchOS(.v4)` ([#19](https://github.com/parse-community/Parse-Swift/pull/19)), thanks to [Corey Baker](https://github.com/cbaker6).
- Fixed bugs in batch and save responses. ([#15](https://github.com/parse-community/Parse-Swift/pull/15)), thanks to [Corey Baker](https://github.com/cbaker6).
- Fix Keychain tests ([#12](https://github.com/parse-community/Parse-Swift/pull/12)), thanks to [Corey Baker](https://github.com/cbaker6).
