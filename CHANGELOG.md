# Parse-Swift Changelog

### main
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.2.6...main)
* _Contributing to this repo? Add info about your change here to be included in the next release_

### 1.2.6
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.2.5...1.2.6)

__Fixes__
- Crash when linking auth types due to server not sending sessionToken ([#109](https://github.com/parse-community/Parse-Swift/pull/109)), thanks to [Corey Baker](https://github.com/cbaker6).

### 1.2.5
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.2.4...1.2.5)

__Fixes__
- Let ParseFacebook accept expiresIn parameter instead of converting to date ([#104](https://github.com/parse-community/Parse-Swift/pull/104)), thanks to [Corey Baker](https://github.com/cbaker6).

### 1.2.4
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.2.3...1.2.4)

__Fixes__
- Ensure all dates are encoded/decoded to the proper UTC time ([#103](https://github.com/parse-community/Parse-Swift/pull/103)), thanks to [Corey Baker](https://github.com/cbaker6).

### 1.2.3
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.2.2...1.2.3)

__Fixes__
- Fixed a bug that prevented custom objectIds from working ([#101](https://github.com/parse-community/Parse-Swift/pull/101)), thanks to [Corey Baker](https://github.com/cbaker6).

### 1.2.2
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.2.1...1.2.2)

__New features__
- Allow custom objectIds ([#100](https://github.com/parse-community/Parse-Swift/pull/100)), thanks to [Corey Baker](https://github.com/cbaker6).
- Add ParseTwitter and ParseFacebook authentication ([#97](https://github.com/parse-community/Parse-Swift/pull/97)), thanks to [Abdulaziz Alhomaidhi](https://github.com/abs8090).
- Add build support for Android ([#90](https://github.com/parse-community/Parse-Swift/pull/90)), thanks to [jt9897253](https://github.com/jt9897253).

__Fixes__
- There was another bug after a user first logs in anonymously and then becomes a real user. The authData sent to the server wasn't stripped, keep the user anonymous instead of making them a real user ([#100](https://github.com/parse-community/Parse-Swift/pull/100)), thanks to [Corey Baker](https://github.com/cbaker6).

### 1.2.1
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.2.0...1.2.1)

__Improvements__
- Child objects are now automatically saved in batches using transactions. This will result in less network overhead and prevent uneccessary clean up of data on the server if a child objects throws an error while saving ([#94](https://github.com/parse-community/Parse-Swift/pull/94)), thanks to [Corey Baker](https://github.com/cbaker6).

__Fixes__
- There was a bug after a user first logs in anonymously and then becomes a real user as the server sends a new sessionToken when this occurs, but the SDK used the old sessionToken, resulting in an invalid sessionToken error ([#94](https://github.com/parse-community/Parse-Swift/pull/94)), thanks to [Corey Baker](https://github.com/cbaker6).

### 1.2.0
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.1.6...1.2.0)

__Breaking changes__
- Allows return types to be specified for `ParseCloud`, query `hint`, and `explain` (see playgrounds for examples). Changed functionality of synchronous `query.first()`. It use to return nil if no values are found. Now it will throw an error if none are found. ([#92](https://github.com/parse-community/Parse-Swift/pull/92)), thanks to [Corey Baker](https://github.com/cbaker6).

__New features__
- Add transaction support to batch saveAll and deleteAll ([#89](https://github.com/parse-community/Parse-Swift/pull/89)), thanks to [Corey Baker](https://github.com/cbaker6).
- Add modifiers to containsString, hasPrefix, hasSuffix ([#85](https://github.com/parse-community/Parse-Swift/pull/85)), thanks to [Corey Baker](https://github.com/cbaker6).

__Improvements__
- Better error reporting when decode errors occur ([#92](https://github.com/parse-community/Parse-Swift/pull/92)), thanks to [Corey Baker](https://github.com/cbaker6).
- Can use a variadic version of exclude. Added examples of select and exclude query in playgrounds ([#88](https://github.com/parse-community/Parse-Swift/pull/88)), thanks to [Corey Baker](https://github.com/cbaker6).

### 1.1.6
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.1.5...1.1.6)

__Fixes__
- Send correct SDK version number to Parse Server ([#84](https://github.com/parse-community/Parse-Swift/pull/84)), thanks to [Corey Baker](https://github.com/cbaker6).

### 1.1.5
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.1.4...1.1.5)

__Improvements__
- Make it easier to use `ParseApple` ([#81](https://github.com/parse-community/Parse-Swift/pull/81)), thanks to [Corey Baker](https://github.com/cbaker6).
- `ParseACL` improvements. Only call `ParseUser.current` when necessary ([#80](https://github.com/parse-community/Parse-Swift/pull/80)), thanks to [Corey Baker](https://github.com/cbaker6).

### 1.1.4
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.1.3...1.1.4)

__New features__
- LDAP authentication support ([#79](https://github.com/parse-community/Parse-Swift/pull/79)), thanks to [Corey Baker](https://github.com/cbaker6).
- Support for push notifications through `ParseInstallation` ([#78](https://github.com/parse-community/Parse-Swift/pull/78)), thanks to [Corey Baker](https://github.com/cbaker6).
- Fetch with include ([#74](https://github.com/parse-community/Parse-Swift/pull/74)), thanks to [Corey Baker](https://github.com/cbaker6).

__Improvements__
- Added `ParseLiveQuery` SwiftUI example to Playgrounds ([#77](https://github.com/parse-community/Parse-Swift/pull/77)), thanks to [Corey Baker](https://github.com/cbaker6).

### 1.1.3
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.1.2...1.1.3)

__New features__
- SwiftUI ready! ([#73](https://github.com/parse-community/Parse-Swift/pull/73)), thanks to [Corey Baker](https://github.com/cbaker6).

__Fixes__
- Fixes some issues with `ParseUser.logout` ([#73](https://github.com/parse-community/Parse-Swift/pull/73)), thanks to [Corey Baker](https://github.com/cbaker6).

### 1.1.2
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.1.1...1.1.2)

__Fixes__
Installing via SPM crashes ([#69](https://github.com/parse-community/Parse-Swift/pull/69)), thanks to [pmmlo](https://github.com/pmmlo).

### 1.1.1
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.1.0...1.1.1)

__Fixes__
- Expose `ParseLiveQuery` subscription properties ([#66](https://github.com/parse-community/Parse-Swift/pull/66)), thanks to [Corey Baker](https://github.com/cbaker6).

### 1.1.0
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.0.2...1.1.0)

__New features__
- Enable `ParseFile` for Linux ([#64](https://github.com/parse-community/Parse-Swift/pull/64)), thanks to [jt9897253](https://github.com/jt9897253).
- Use a `ParseLiveQuery` subscription as a SwiftUI view model ([#65](https://github.com/parse-community/Parse-Swift/pull/65)), thanks to [Corey Baker](https://github.com/cbaker6).
- Idempotency support ([#62](https://github.com/parse-community/Parse-Swift/pull/62)), thanks to [Corey Baker](https://github.com/cbaker6).

### 1.0.2
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.0.0...1.0.2)

__New features__
- Linux support. See the PR for limitations ([#59](https://github.com/parse-community/Parse-Swift/pull/59)), thanks to [Corey Baker](https://github.com/cbaker6).

### 1.0.0

__New features__
- Config support ([#56](https://github.com/parse-community/Parse-Swift/pull/56)), thanks to [Corey Baker](https://github.com/cbaker6) and [Tom Fox](https://github.com/TomWFox).
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
