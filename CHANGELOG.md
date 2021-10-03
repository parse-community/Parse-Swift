# Parse-Swift Changelog

### main
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.10.1...main)
* _Contributing to this repo? Add info about your change here to be included in the next release_

### 1.10.2
__Improvements__
- Added an extension to compare a Swift Error with a single ParseError or multiple ParseErrors ([#250](https://github.com/parse-community/Parse-Swift/pull/250)), thanks to [Damian Van de Kauter](https://github.com/novemTeam).

### 1.10.1
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.10.0...1.10.1)

__Improvements__
- Removes emptyObject requirement that was added in #243. Instead, has a recommendation in playgrounds on how to use emptyObject to only send select modified keys to the server ([#249](https://github.com/parse-community/Parse-Swift/pull/249)), thanks to [Corey Baker](https://github.com/cbaker6).

### 1.10.0
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.9.10...1.10.0)

__Improvements__
- (Breaking Change) Provide ParseObject property, emptyObject, that makes it easy to send only modified keys to the server. This change "might" be breaking depending on your implementation as it requires ParseObjects to now have an empty initializer, init() ([#243](https://github.com/parse-community/Parse-Swift/pull/243)), thanks to [Corey Baker](https://github.com/cbaker6).

__Fixes__
- ParseUser shouldn't send email if it hasn't been modified or else email verification is resent ([#241](https://github.com/parse-community/Parse-Swift/pull/241)), thanks to [Corey Baker](https://github.com/cbaker6).

### 1.9.10
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.9.9...1.9.10)

__Fixes__
- ParseInstallation can't be retreived from Keychain after the first fun ([#236](https://github.com/parse-community/Parse-Swift/pull/236)), thanks to [Corey Baker](https://github.com/cbaker6).

### 1.9.9
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.9.8...1.9.9)

__Fixes__
- Saving ParseObjects with ParseFile properties now saves files on background queue ([#230](https://github.com/parse-community/Parse-Swift/pull/230)), thanks to [Corey Baker](https://github.com/cbaker6).

### 1.9.8
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.9.7...1.9.8)

__Fixes__
- Use a seperate Keychain for each app bundleId. This only effects macOS apps as their Keychain is handled by the OS differently. For macOS app developers only, the user who logged in last to your app will have their Keychain upgraded to the patched version. Other users/apps will either need to login again or logout then login again ([#224](https://github.com/parse-community/Parse-Swift/pull/224)), thanks to [Corey Baker](https://github.com/cbaker6).

### 1.9.7
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.9.6...1.9.7)

__Improvements__
- Properly allow a mixed custom objectId environment without compromising safety checks using .save(). If a developer wants to ignore the objectId checks, they need to specify isIgnoreCustomObjectIdConfig = true each time ([#222](https://github.com/parse-community/Parse-Swift/pull/222)), thanks to [Corey Baker](https://github.com/cbaker6).

### 1.9.6
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.9.5...1.9.6)

__Fixes__
- Query withinMiles and withinKilometers was not returning unsorted results when sort=false ([#219](https://github.com/parse-community/Parse-Swift/pull/219)), thanks to [Corey Baker](https://github.com/cbaker6).

### 1.9.5
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.9.4...1.9.5)

__Improvements__
- LiveQuery web socket connections handle URL error codes -1001 "The request timed out" and -1011 "There was a bad response from the server." ([#217](https://github.com/parse-community/Parse-Swift/pull/217)), thanks to [Lukas Smilek](https://github.com/lsmilek1).

### 1.9.4
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.9.3...1.9.4)

__Fixes__
- Fix LiveQuery reconnections when server disconnects. Always receive and pass connection errors to ParseLiveQuery delegate ([#211](https://github.com/parse-community/Parse-Swift/pull/211)), thanks to [Corey Baker](https://github.com/cbaker6).

### 1.9.3
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.9.2...1.9.3)

__Improvements__
- Ensure delegate set before resuming a ParseLiveQuery task ([#209](https://github.com/parse-community/Parse-Swift/pull/209)), thanks to [Corey Baker](https://github.com/cbaker6).

### 1.9.2
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.9.1...1.9.2)

__Improvements__
- ParseLiveQuery checks all states of a websocket and reacts as needed after an error ([#207](https://github.com/parse-community/Parse-Swift/pull/207)), thanks to [Corey Baker](https://github.com/cbaker6).

### 1.9.1
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.9.0...1.9.1)

__Improvements__
- Clear caching when a user logs out ([#198](https://github.com/parse-community/Parse-Swift/pull/198)), thanks to [Corey Baker](https://github.com/cbaker6).
- Close all LiveQuery connections when a user logs out ([#199](https://github.com/parse-community/Parse-Swift/pull/199)), thanks to [Corey Baker](https://github.com/cbaker6).
- ParseLiveQuery attempts to reconnect upon disconnection error ([#204](https://github.com/parse-community/Parse-Swift/pull/204)), thanks to [Corey Baker](https://github.com/cbaker6).
- Make ParseFileManager public so developers can easily find the location of ParseFiles ([#205](https://github.com/parse-community/Parse-Swift/pull/205)), thanks to [Corey Baker](https://github.com/cbaker6).

__Fixes__
- Fix Facebook and Twitter login setting incorrect keys ([#202](https://github.com/parse-community/Parse-Swift/pull/202)), thanks to [Daniel Blyth](https://github.com/dblythy).

### 1.9.0
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.8.6...1.9.0)

__New features__
- (Breaking Change) Added a new type, QueryViewModel which conforms to ObservableObject. The new type serves as a view model property for any Parse Query. Simply call query.viewModel to use the view model with any SwiftUI view. QueryViewModel can be subclassed for customization. In addition, developers can create their own view models for queries by conforming to QueryObservable. LiveQuery Subscription's inherrit from QueryViewModel meaning instances of Subscription provides a single view model that publishes updates from LiveQuery events and traditional find, first, count, and aggregate queries. A breaking change is introduced for those use custom subscriptions as ParseSubscription has been renamed to QuerySubscribable ([#183](https://github.com/parse-community/Parse-Swift/pull/183)), thanks to [Corey Baker](https://github.com/cbaker6).
- Added a new type, CloudViewModel which conforms to ObservableObject. The new type serves as a view model property for any Cloud Code. Simply call cloud.viewModel to use the view model with any SwiftUI view. CloudViewModel can be subclassed for customization. In addition, developers can create their own view models for queries by conforming to CloudObservable ([#183](https://github.com/parse-community/Parse-Swift/pull/183)), thanks to [Corey Baker](https://github.com/cbaker6).
- Added two missing Parse types, ParseBytes and ParsePolygon ([#190](https://github.com/parse-community/Parse-Swift/pull/190)), thanks to [Corey Baker](https://github.com/cbaker6).
- Added caching of http requests along with adding additional headers. Caching and additional headers can be set when initializing the SDK. Caching can also be set per request using API.Options ([#196](https://github.com/parse-community/Parse-Swift/pull/196)), thanks to [Corey Baker](https://github.com/cbaker6).

__Improvements__
- Removed CommonCrypto and now uses encoded string as a hash for child ParseObjects across all OS's ([#184](https://github.com/parse-community/Parse-Swift/pull/184)), thanks to [Corey Baker](https://github.com/cbaker6).
- All types now conform to CustomStringConvertible ([#185](https://github.com/parse-community/Parse-Swift/pull/185)), thanks to [Corey Baker](https://github.com/cbaker6).
- Setting limit = 0 of a query doesn't query the server and instead just returns empty or no results depending on the query ([#189](https://github.com/parse-community/Parse-Swift/pull/189)), thanks to [Corey Baker](https://github.com/cbaker6).
- ParseGeoPoint initializer now throws if geopoints are out-of-bounds instead of asserting ([#190](https://github.com/parse-community/Parse-Swift/pull/190)), thanks to [Corey Baker](https://github.com/cbaker6).
- Persist all properties of ParseUser and ParseInstallation to keychain so they can be accessed via current. Developers don't have to fetch the ParseUser or ParseInstlation after app restart anymore ([#191](https://github.com/parse-community/Parse-Swift/pull/191)), thanks to [Corey Baker](https://github.com/cbaker6).

__Fixes__
- Fixed a bug when signing up from a ParseUser instance resulted in custom keys not being persisted to the keychain ([#187](https://github.com/parse-community/Parse-Swift/pull/187)), thanks to [Corey Baker](https://github.com/cbaker6).
- Fixed a bug where countExplain query result wasn't returned as an array  ([#189](https://github.com/parse-community/Parse-Swift/pull/189)), thanks to [Corey Baker](https://github.com/cbaker6).
- The query withinPolygon(key: String, points: [ParseGeoPoint]) now works correctly and sends an array of doubles instead of an array of GeoPoint's ([#190](https://github.com/parse-community/Parse-Swift/pull/190)), thanks to [Corey Baker](https://github.com/cbaker6).
- Fixed a bug where the ParseEncoder incorrectly detects a circular dependency when two child objects are the same ([#194](https://github.com/parse-community/Parse-Swift/pull/194)), thanks to [Corey Baker](https://github.com/cbaker6).
- Make sure all LiveQuery socket changes are received on the correct queue to prevent threading issues ([#195](https://github.com/parse-community/Parse-Swift/pull/195)), thanks to [Corey Baker](https://github.com/cbaker6).

### 1.8.6
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.8.5...1.8.6)

__Improvements__
- Added SwiftUI query combine example to playgrounds. Skip id when encoding ParseObjects ([#181](https://github.com/parse-community/Parse-Swift/pull/181)), thanks to [Corey Baker](https://github.com/cbaker6).
- Persist current SDK version for migrating between versions ([#182](https://github.com/parse-community/Parse-Swift/pull/182)), thanks to [Corey Baker](https://github.com/cbaker6).

### 1.8.5
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.8.4...1.8.5)

__Fixes__
- Fixed a bug in LiveQuery when a close frame is sent from the server that resulted in closing
all running websocket tasks instead of the particular task the request was intended for. The fix
includes a new delegate method named `closedSocket()` which provides the close code
and reason the server closed the connection ([#176](https://github.com/parse-community/Parse-Swift/pull/176)), thanks to [Corey Baker](https://github.com/cbaker6).

### 1.8.4
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.8.3...1.8.4)

__Fixes__
- Switched context header X-Parse-Context to X-Parse-Cloud-Context to match server ([#170](https://github.com/parse-community/Parse-Swift/pull/170)), thanks to [Corey Baker](https://github.com/cbaker6).
- Fixed a bug in LiveQuery that prevented reconnecting after a connection was closed. Also added a sendPing method to LiveQuery ([#172](https://github.com/parse-community/Parse-Swift/pull/172)), thanks to [Corey Baker](https://github.com/cbaker6).

### 1.8.3
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.8.2...1.8.3)

__Fixes__
- Fixed a bug that prevented saving ParseObjects that had Pointers as properties ([#169](https://github.com/parse-community/Parse-Swift/pull/169)), thanks to [Corey Baker](https://github.com/cbaker6).

### 1.8.2
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.8.1...1.8.2)

__Improvements__
- Ensure pipeline and fields are checked when comparing queries ([#163](https://github.com/parse-community/Parse-Swift/pull/163)), thanks to [Corey Baker](https://github.com/cbaker6).
- Allow custom error codes to be thrown from Cloud Functions ([#165](https://github.com/parse-community/Parse-Swift/pull/165)), thanks to [Daniel Blyth](https://github.com/dblythy).

### 1.8.1
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.8.0...1.8.1)

__Improvements__
- Append instead of replace when using query select, exclude, include, and fields ([#155](https://github.com/parse-community/Parse-Swift/pull/155)), thanks to [Corey Baker](https://github.com/cbaker6).

__Fixes__
- Transactions currently don't work when using mongoDB(postgres does work) on the parse-server. Internal use of transactions are disabled by default. If you want the Swift SDK to use transactions internally, you need to set useTransactionsInternally=true when configuring the client. It is recommended not to use transactions if you are using mongoDB until it's fixed on the server ([#158](https://github.com/parse-community/Parse-Swift/pull/158)), thanks to [Corey Baker](https://github.com/cbaker6).

### 1.8.0
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.7.2...1.8.0)

__New features__
- Add ParseAnalytics. Requires app tracking authorization in latest OS's ([#147](https://github.com/parse-community/Parse-Swift/pull/147)), thanks to [Corey Baker](https://github.com/cbaker6).

__Improvements__
- Adds the ability to directly use == as a QueryConstraint on a field that's a ParseObject ([#147](https://github.com/parse-community/Parse-Swift/pull/147)), thanks to [Corey Baker](https://github.com/cbaker6).
- Future proof SDK by always sending client version header. Also added http method PATCH to API for future use ([#146](https://github.com/parse-community/Parse-Swift/pull/146)), thanks to [Corey Baker](https://github.com/cbaker6).

__Fixes__
- Fixed an error that occured when deleting a ParseFile which resulted in the file being downloaded locally ([#147](https://github.com/parse-community/Parse-Swift/pull/147)), thanks to [Corey Baker](https://github.com/cbaker6).

### 1.7.2
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.7.1...1.7.2)

__New features__
- Added ability to send context with object by specifying it within options ([#140](https://github.com/parse-community/Parse-Swift/pull/140)), thanks to [Corey Baker](https://github.com/cbaker6).

__Fixes__
- ParseFiles can't be updated from the client and will now throw an error if attempted. Instead another file should be created and the older file should be deleted by the developer. ([#144](https://github.com/parse-community/Parse-Swift/pull/144)), thanks to [Corey Baker](https://github.com/cbaker6).
- Fixed issue where Swift SDK prevented fetching of Parse objects when custom objectId was enabled ([#139](https://github.com/parse-community/Parse-Swift/pull/139)), thanks to [Corey Baker](https://github.com/cbaker6).

__Improvements__
- Add playground example of saving Parse objects with a custom objectId ([#137](https://github.com/parse-community/Parse-Swift/pull/137)), thanks to [Corey Baker](https://github.com/cbaker6).
- Improved comparison of query constraints by comparing value ([#140](https://github.com/parse-community/Parse-Swift/pull/140)), thanks to [Corey Baker](https://github.com/cbaker6).

### 1.7.1
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.7.0...1.7.1)

__New features__
- Can now check the health of a Parse Server using ParseHealth. ([#134](https://github.com/parse-community/Parse-Swift/pull/134)), thanks to [Corey Baker](https://github.com/cbaker6).

### 1.7.0
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.6.0...1.7.0)

__Improvements__
- Add emailVerified to ParseUser. Make relative query take a QueryConstraint as an argument. Add more documentation ([#129](https://github.com/parse-community/Parse-Swift/pull/129)), thanks to [Corey Baker](https://github.com/cbaker6).

### 1.6.0
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.5.1...1.6.0)

__Improvements__
- Make AnyCodable internal. If developers want to use AnyCodable, AnyEncodable, or AnyDecodable for `explain` or `ParseCloud`, they should add the [AnyCodable](https://github.com/Flight-School/AnyCodable) package to their app. In addition developers can create their own type-erased wrappers or use whatever they desire ([#127](https://github.com/parse-community/Parse-Swift/pull/127)), thanks to [Corey Baker](https://github.com/cbaker6).

### 1.5.1
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.5.0...1.5.1)

__Improvements__
- Update ParseError to match server and make ParseError and ParseObject Pointer documentation public ([#125](https://github.com/parse-community/Parse-Swift/pull/125)), thanks to [Corey Baker](https://github.com/cbaker6).

### 1.5.0
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.4.0...1.5.0)

__Improvements__
- (Breaking Change) Aggregrate takes any Encodable type. Query planning methods are now: findExlpain, firstEplain, countExplain, etc. The distinct query now works. The client will also not throw an error anymore when attempting to delete a File and the masterKey isn't available. The developer will still need to configure the server to delete the file properly ([#122](https://github.com/parse-community/Parse-Swift/pull/122)), thanks to [Corey Baker](https://github.com/cbaker6).

### 1.4.0
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.3.1...1.4.0)

__Improvements__
- (Breaking Change) A query hint can now be set using a method and its return type is automatically inferred. In addition, a hint can now be any Encodable type instead of just a String ([#119](https://github.com/parse-community/Parse-Swift/pull/119)), thanks to [Corey Baker](https://github.com/cbaker6).

### 1.3.1
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.3.0...1.3.1)

__New features__
- Add findAll query to find all objects ([#118](https://github.com/parse-community/Parse-Swift/pull/118)), thanks to [Corey Baker](https://github.com/cbaker6).
- Can now delete the iOS Objective-C SDK Keychain from app ([#118](https://github.com/parse-community/Parse-Swift/pull/118)), thanks to [Corey Baker](https://github.com/cbaker6).
- Migrate installationId from obj-c SDK ([#117](https://github.com/parse-community/Parse-Swift/pull/117)), thanks to [Corey Baker](https://github.com/cbaker6).

__Improvements__
- Added ability to initialize SDK with ParseConfiguration. Can now update certificate pinning authorization after SDK is initializated ([#117](https://github.com/parse-community/Parse-Swift/pull/117)), thanks to [Corey Baker](https://github.com/cbaker6).

### 1.3.0
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.2.6...1.3.0)

__Improvements__
- (Breaking Change) No longer require dispatch to main queue when using ParseInstallation. The side effect of this is badge is no longer retrieved by the SDK. The developer should retrieve the badge count on their own and save it to `ParseInstallation` if they require badge ([#114](https://github.com/parse-community/Parse-Swift/pull/114)), thanks to [Corey Baker](https://github.com/cbaker6).

__Fixes__
- (Breaking Change) Correctly saves objectId of ParseInstallation to Keychain when saving to server. Also fixes issue when using deleteAll with current ParseUser and ParseInstallation. Old installations will automatically be migrated to the new one. If you end up having issues you can delete all of the installations in your ParseDashboard that were created with Parse-Swift < 1.30. If you are not able to do this, you can all log out of devices using Parse-Swift < 1.30 and then log back in ([#116](https://github.com/parse-community/Parse-Swift/pull/116)), thanks to [Corey Baker](https://github.com/cbaker6).

### 1.2.6
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.2.5...1.2.6)

__Fixes__
- Recreate installation automatically after deletion from Keychain ([#112](https://github.com/parse-community/Parse-Swift/pull/112)), thanks to [Corey Baker](https://github.com/cbaker6).
- Error when linking auth types due to server not sending sessionToken ([#109](https://github.com/parse-community/Parse-Swift/pull/109)), thanks to [Corey Baker](https://github.com/cbaker6).

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

__New features__
- Add transaction support to batch saveAll and deleteAll ([#89](https://github.com/parse-community/Parse-Swift/pull/89)), thanks to [Corey Baker](https://github.com/cbaker6).
- Add modifiers to containsString, hasPrefix, hasSuffix ([#85](https://github.com/parse-community/Parse-Swift/pull/85)), thanks to [Corey Baker](https://github.com/cbaker6).

__Improvements__
- (Breaking Change) Allows return types to be specified for `ParseCloud`, query `hint`, and `explain` (see playgrounds for examples). Changed functionality of synchronous `query.first()`. It use to return nil if no values are found. Now it will throw an error if none are found. ([#92](https://github.com/parse-community/Parse-Swift/pull/92)), thanks to [Corey Baker](https://github.com/cbaker6).
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
