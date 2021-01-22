# Parse-Swift Changelog

### main
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.0.0...main)
* _Contributing to this repo? Add info about your change here to be included in next release_

__New features__
- Role and Relation support. Also improved Parse operations and added examples in Playgrounds ([#54](https://github.com/parse-community/Parse-Swift/pull/54)), thanks to [Corey Baker](https://github.com/cbaker6) and [Tom Fox](https://github.com/TomWFox).
- Added more `Query` support for distinct, aggregate, nor, containedBy, and relative time ([#54](https://github.com/parse-community/Parse-Swift/pull/54)), thanks to [Corey Baker](https://github.com/cbaker6) and [Tom Fox](https://github.com/TomWFox).
- Annonymous and Apple login along with `ParseAuthentication` protocol for support of any adapter ([#53](https://github.com/parse-community/Parse-Swift/pull/53)), thanks to [Corey Baker](https://github.com/cbaker6) and [Tom Fox](https://github.com/TomWFox).
- Developer side network authentication for certificate pinning. Parse-Swift can share authentication with `ParseLiveQuery` or they can use seperate ([#45](https://github.com/parse-community/Parse-Swift/pull/45)), thanks to [Corey Baker](https://github.com/cbaker6) and [Tom Fox](https://github.com/TomWFox).
- Full LiveQuery support (min requirement: macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0) ([#45](https://github.com/parse-community/Parse-Swift/pull/45)), thanks to [Corey Baker](https://github.com/cbaker6) and [Tom Fox](https://github.com/TomWFox).
- Support of Cloud and Job functions along with password reset and verification email request ([#43](https://github.com/parse-community/Parse-Swift/pull/43)), thanks to [Corey Baker](https://github.com/cbaker6) and [Tom Fox](https://github.com/TomWFox).
- Add `ParseFile` support ([#40](https://github.com/parse-community/Parse-Swift/pull/40)), thanks to [Corey Baker](https://github.com/cbaker6).
- Add `deleteAll` to Parse objects ([#34](https://github.com/parse-community/Parse-Swift/pull/34)), thanks to [Corey Baker](https://github.com/cbaker6).
- Save child pointers and deep saving of objects ([#21](https://github.com/parse-community/Parse-Swift/pull/21)), thanks to [Corey Baker](https://github.com/cbaker6).
- Persist `ParseUser`, `ParseInstallation`, and default `ParseACL` to Keychain ([#19](https://github.com/parse-community/Parse-Swift/pull/19)), thanks to [Corey Baker](https://github.com/cbaker6).
- Add PrimitiveObectStore protocol that extends Keychain Store ([#13](https://github.com/parse-community/Parse-Swift/pull/13)), thanks to [Pranjal Satija](https://github.com/pranjalsatija).
- Add `AnyCodable` support ([#12](https://github.com/parse-community/Parse-Swift/pull/12)), thanks to [Corey Baker](https://github.com/cbaker6) and [Shawn Baek](https://github.com/ShawnBaek).
- Add Keychain storage ([#7](https://github.com/parse-community/Parse-Swift/pull/7)), thanks to [Florent Vilmart](https://github.com/flovilmart).
- Add `ParseError`, SwiftLint, saveAll, SPM, synchronous support ([#6](https://github.com/parse-community/Parse-Swift/pull/6)), thanks to [Florent Vilmart](https://github.com/flovilmart).
- Create Parse-Swift project, project Playground, and add Travis CI ([#1](https://github.com/parse-community/Parse-Swift/pull/1)), thanks to [Florent Vilmart](https://github.com/flovilmart).

__Improvements__
- Naming conventions and structure ([#54](https://github.com/parse-community/Parse-Swift/pull/54)), thanks to [Corey Baker](https://github.com/cbaker6) and [Tom Fox](https://github.com/TomWFox).
- Improve network progress updates and threading ([#51](https://github.com/parse-community/Parse-Swift/pull/51)), thanks to [Corey Baker](https://github.com/cbaker6).
- User login now uses `POST` instead of `GET` ([#45](https://github.com/parse-community/Parse-Swift/pull/45)), thanks to [Corey Baker](https://github.com/cbaker6) and [Tom Fox](https://github.com/TomWFox).
- Dedicated Parse URLSession for more control and delegation ([#45](https://github.com/parse-community/Parse-Swift/pull/45)), thanks to [Corey Baker](https://github.com/cbaker6) and [Tom Fox](https://github.com/TomWFox).
- Objects are batched in groups of 50 ([#43](https://github.com/parse-community/Parse-Swift/pull/43)), thanks to [Corey Baker](https://github.com/cbaker6) and [Tom Fox](https://github.com/TomWFox).
- Add default queues to async calls ([#38](https://github.com/parse-community/Parse-Swift/pull/38)), thanks to [Corey Baker](https://github.com/cbaker6).
- Persist queried and fetch objects to Keychain if they match a `current` object already stored ([#34](https://github.com/parse-community/Parse-Swift/pull/34)), thanks to [Corey Baker](https://github.com/cbaker6).
- Improve ParseEncoder to support arrays ([#33](https://github.com/parse-community/Parse-Swift/pull/33)), thanks to [Corey Baker](https://github.com/cbaker6).
- Add a new ParseEncoder from Swift 5.3 open-source JSON encoder ([#21](https://github.com/parse-community/Parse-Swift/pull/21)), thanks to [Corey Baker](https://github.com/cbaker6).
- Full support of `ParseGeopoint` and improve querying ([#21](https://github.com/parse-community/Parse-Swift/pull/21)), thanks to [Corey Baker](https://github.com/cbaker6) and [Tom Fox](https://github.com/TomWFox).
- Improved async networking calls ([#15](https://github.com/parse-community/Parse-Swift/pull/15)), thanks to [Corey Baker](https://github.com/cbaker6).
- Rename and restructure project ([#13](https://github.com/parse-community/Parse-Swift/pull/13)), thanks to [Pranjal Satija](https://github.com/pranjalsatija).
- Update to Swift 5.0 ([#12](https://github.com/parse-community/Parse-Swift/pull/12)), thanks to [Corey Baker](https://github.com/cbaker6).
- Remove RESTCommand and add API.Command ([#6](https://github.com/parse-community/Parse-Swift/pull/6)), thanks to [Florent Vilmart](https://github.com/flovilmart).

__Fixes__
- Delete current installation during logout ([#52](https://github.com/parse-community/Parse-Swift/pull/52)), thanks to [Corey Baker](https://github.com/cbaker6).
- Parse server supports `$eq`, but this isn't supported by LiveQueryServer, switched to supported ([#48](https://github.com/parse-community/Parse-Swift/pull/48)), thanks to [Corey Baker](https://github.com/cbaker6).
- Bug when updating a ParseObject bug where objects was accidently converted to pointers ([#48](https://github.com/parse-community/Parse-Swift/pull/48)), thanks to [Corey Baker](https://github.com/cbaker6).
- User logout was calling the wrong endpoint ([#43](https://github.com/parse-community/Parse-Swift/pull/43)), thanks to [Corey Baker](https://github.com/cbaker6) and [Tom Fox](https://github.com/TomWFox).
- Fix an issue where ACL was overwritten with nil ([#40](https://github.com/parse-community/Parse-Swift/pull/40)), thanks to [Corey Baker](https://github.com/cbaker6).
- Update Keychain during fetch. Fix synchronous bug that occured with `ParseError` was thrown ([#38](https://github.com/parse-community/Parse-Swift/pull/38)), thanks to [Corey Baker](https://github.com/cbaker6).
- Fix ParseEncoder bugs ([#27](https://github.com/parse-community/Parse-Swift/pull/27)), thanks to [Corey Baker](https://github.com/cbaker6).
- Fix async callback queue bug ([#27](https://github.com/parse-community/Parse-Swift/pull/27)), thanks to [Corey Baker](https://github.com/cbaker6).
- Fix bugs in ParseACL and bump minimum OS support to `.iOS(.v11), .macOS(.v10_13), .tvOS(.v11), .watchOS(.v4)` ([#19](https://github.com/parse-community/Parse-Swift/pull/19)), thanks to [Corey Baker](https://github.com/cbaker6).
- Fix bugs in batch and save responses ([#15](https://github.com/parse-community/Parse-Swift/pull/15)), thanks to [Corey Baker](https://github.com/cbaker6).
- Fix Keychain tests ([#12](https://github.com/parse-community/Parse-Swift/pull/12)), thanks to [Corey Baker](https://github.com/cbaker6).
