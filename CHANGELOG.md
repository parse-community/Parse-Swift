# Parse-Swift Changelog

### main
[Full Changelog](https://github.com/netreconlab/Parse-Swift/compare/4.16.1...main), [Documentation](https://swiftpackageindex.com/netreconlab/Parse-Swift/main/documentation/parseswift)
* _Contributing to this repo? Add info about your change here to be included in the next release_

### 4.16.0
[Full Changelog](https://github.com/netreconlab/Parse-Swift/compare/4.16.0...4.16.1), [Documentation](https://swiftpackageindex.com/netreconlab/Parse-Swift/4.16.1/documentation/parseswift)

__Fixes__
- Querying using findAll throws a hang risk warning in Xcode 14 ([#14](https://github.com/netreconlab/Parse-Swift/pull/10)), thanks to [Corey Baker](https://github.com/cbaker6).

### 4.16.0
[Full Changelog](https://github.com/netreconlab/Parse-Swift/compare/4.15.2...4.16.0), [Documentation](https://swiftpackageindex.com/netreconlab/Parse-Swift/4.16.0/documentation/parseswift)

__New features__
- Added the ability to check if a `ParseObject` key is dirty ([#9](https://github.com/netreconlab/Parse-Swift/pull/9)), thanks to [Corey Baker](https://github.com/cbaker6).

__Fixes__
- Fixed an issue where the name propery of a ParseRole may not be restored after updating a ParseRole on the server ([#10](https://github.com/netreconlab/Parse-Swift/pull/10)), thanks to [Corey Baker](https://github.com/cbaker6).

### 4.15.2
[Full Changelog](https://github.com/netreconlab/Parse-Swift/compare/4.15.1...4.15.2), [Documentation](https://swiftpackageindex.com/netreconlab/Parse-Swift/4.15.2/documentation/parseswift)

__Fixes__
- Fixed an issue that prevented nested ParseObjects and ParsFiles from saving correctly in some cases ([#8](https://github.com/netreconlab/Parse-Swift/pull/8)), thanks to [Corey Baker](https://github.com/cbaker6).

### 4.15.1
[Full Changelog](https://github.com/netreconlab/Parse-Swift/compare/4.15.0...4.15.1), [Documentation](https://swiftpackageindex.com/netreconlab/Parse-Swift/4.15.1/documentation/parseswift)

__Fixes__
- Fixed ambigous SDK initializer ([#6](https://github.com/netreconlab/Parse-Swift/pull/6)), thanks to [Corey Baker](https://github.com/cbaker6).

### 4.15.0
[Full Changelog](https://github.com/netreconlab/Parse-Swift/compare/4.14.2...4.15.0), [Documentation](https://swiftpackageindex.com/netreconlab/Parse-Swift/4.15.0/documentation/parseswift)

__New features__
- Refactored masterKey->primaryKey due to insensitive language ([#2](https://github.com/netreconlab/Parse-Swift/pull/2)), thanks to [Corey Baker](https://github.com/cbaker6).

### 4.14.2
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/4.14.1...4.14.2), [Documentation](https://swiftpackageindex.com/parse-community/Parse-Swift/4.14.2/documentation/parseswift)

__Fixes__
- Addressed an issue that prevented updating ParseObjects with saveAll ([#423](https://github.com/parse-community/Parse-Swift/pull/423)), thanks to [Corey Baker](https://github.com/cbaker6).

### 4.14.1
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/4.14.0...4.14.1), [Documentation](https://swiftpackageindex.com/parse-community/Parse-Swift/4.14.1/documentation/parseswift)

__Fixes__
- For Swift 5.5.2+ all asynchronous methods that attempt to save, create, update, or replace use the async/await version of deep saving ParseObjects. This fixes any purple warnings caused by the SDK in Xcode. Older Swift versions use the synchronous version of deep saving ([#418](https://github.com/parse-community/Parse-Swift/pull/418)), thanks to [Corey Baker](https://github.com/cbaker6).
- Can catch when the Parse Server throws an improper ParseError that only contains "error" or "message", but does not contain a "code" ([#418](https://github.com/parse-community/Parse-Swift/pull/418)), thanks to [Corey Baker](https://github.com/cbaker6).

### 4.14.0
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/4.13.1...4.14.0), [Documentation](https://swiftpackageindex.com/parse-community/Parse-Swift/4.14.0/documentation/parseswift)

__New features__
- Add file caching using the Parse download folder ([#416](https://github.com/parse-community/Parse-Swift/pull/416)), thanks to [Corey Baker](https://github.com/cbaker6).

### 4.13.1
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/4.13.0...4.13.1), [Documentation](https://swiftpackageindex.com/parse-community/Parse-Swift/4.13.1/documentation/parseswift)

__Fixes__
- Remove ParseFile caching due to OS not having a natural way to cache files. Instead, if developers want to access a saved ParseFile, they should check the download directory for the respective file name ([#414](https://github.com/parse-community/Parse-Swift/pull/414)), thanks to [Corey Baker](https://github.com/cbaker6).

### 4.13.0
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/4.12.0...4.13.0), [Documentation](https://swiftpackageindex.com/parse-community/Parse-Swift/4.13.0/documentation/parseswift)

__New features__
- Add helper methods to ParseFileTransferable protocol to assist with creating propper responses to file uploads ([#411](https://github.com/parse-community/Parse-Swift/pull/411)), thanks to [Corey Baker](https://github.com/cbaker6).

__Fixes__
- Remove cached error responses when decoding errors occur ([#411](https://github.com/parse-community/Parse-Swift/pull/411)), thanks to [Corey Baker](https://github.com/cbaker6).

### 4.12.0
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/4.11.0...4.12.0), [Documentation](https://swiftpackageindex.com/parse-community/Parse-Swift/4.12.0/documentation/parseswift)

__New features__
- Add the ParseFileTransferable protocol for overriding the default transfer behavior for ParseFile's. Allows for direct uploads to other file storage providers ([#410](https://github.com/parse-community/Parse-Swift/pull/410)), thanks to [Corey Baker](https://github.com/cbaker6).
- Add the become method to ParseInstallation which allows any ParseInstallation to be copied to the current installation. This method can be used to migrate any ParseInstallation to the current installation in the Swift SDK  ([#407](https://github.com/parse-community/Parse-Swift/pull/407)), thanks to [Corey Baker](https://github.com/cbaker6).

__Fixes__
- Properly get the session token from the Parse Objective-C Keychain when using ParseUser.loginUsingObjCKeychain  ([#407](https://github.com/parse-community/Parse-Swift/pull/407)), thanks to [Corey Baker](https://github.com/cbaker6).

### 4.11.0
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/4.10.0...4.11.0), [Documentation](https://swiftpackageindex.com/parse-community/Parse-Swift/4.11.0/documentation/parseswift)

__New features__
- Add a set method that developers can call on their ParseObjects which automatically sends updated properties to a Parse Server and merges those updates with the original ParseObject locally. The feature removes the requirement to call mergeable and implement merge(), but comes at additional computational overhead ([#406](https://github.com/parse-community/Parse-Swift/pull/406)), thanks to [Corey Baker](https://github.com/cbaker6).

### 4.10.0
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/4.9.3...4.10.0), [Documentation](https://swiftpackageindex.com/parse-community/Parse-Swift/4.10.0/documentation/parseswift)

__New features__
- Add a new operation method that allows developers to set a new value to a KeyPath without needing the string version of the key. Also adds the get() method to allow developers to get the unwrapped property of any ParseObject based on its KeyPath ([#403](https://github.com/parse-community/Parse-Swift/pull/403)), thanks to [Corey Baker](https://github.com/cbaker6).
- Add revertKeyPath() and revertObject() methods to ParseObject which allow developers to revert to original values of key paths or objects after mutating ParseObjects that already have an objectId  ([#402](https://github.com/parse-community/Parse-Swift/pull/402)), thanks to [Corey Baker](https://github.com/cbaker6).

### 4.9.3
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/4.9.2...4.9.3), [Documentation](https://swiftpackageindex.com/parse-community/Parse-Swift/4.9.3/documentation/parseswift)

__Fixes__
- When saving ParseFiles locally, files that have a directory in their filename save correctly instead of throwing an error on the client ([#399](https://github.com/parse-community/Parse-Swift/pull/399)), thanks to [Corey Baker](https://github.com/cbaker6).
- Default to not setting kSecUseDataProtectionKeychain to true as this can cause issues with querying the Keychain in Swift Playgrounds or other apps that cannot setup the Keychain on macOS. This behavior can be changed by setting usingDataProtectionKeychain to true when initializing the SDK ([#398](https://github.com/parse-community/Parse-Swift/pull/398)), thanks to [Corey Baker](https://github.com/cbaker6).

### 4.9.2
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/4.9.1...4.9.2), [Documentation](https://swiftpackageindex.com/parse-community/Parse-Swift/4.9.2/documentation/parseswift)

__Fixes__
- Allow fully qualified ParseSwift types to be used externally by fixing clash with module name ([#397](https://github.com/parse-community/Parse-Swift/pull/397)), thanks to [Corey Baker](https://github.com/cbaker6).

### 4.9.1
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/4.9.0...4.9.1), [Documentation](https://swiftpackageindex.com/parse-community/Parse-Swift/4.9.1/documentation/parseswift)

__Fixes__
- Corrects a memory leak where multiple Parse URLSessions can get created. Use an actor for the url session delegates to ensure thread safety when making async calls in parallel ([#394](https://github.com/parse-community/Parse-Swift/pull/394)), thanks to [Corey Baker](https://github.com/cbaker6).

### 4.9.0
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/4.8.0...4.9.0), [Documentation](https://swiftpackageindex.com/parse-community/Parse-Swift/4.9.0/documentation/parseswift)

__New features__
- Add methods for migrating users and installations from the Parse Objective-C SDK to the Swift SDK ([#391](https://github.com/parse-community/Parse-Swift/pull/391)), thanks to [Corey Baker](https://github.com/cbaker6).
- Enable query caching by using GET instead of POST. GET is now used by default. To switch back to POST, set usingPostForQuery = true when initializing the SDK which will automatically disable all query caching ([#386](https://github.com/parse-community/Parse-Swift/pull/386)), thanks to [Corey Baker](https://github.com/cbaker6).
- Add setAccessGroup method which allows the Parse Keychain to be shared with app extensions and iCloud accounts ([#378](https://github.com/parse-community/Parse-Swift/pull/378)), thanks to [Corey Baker](https://github.com/cbaker6).

__Improvements__
- Add more details to error messages related when decoding errors occur ([#388](https://github.com/parse-community/Parse-Swift/pull/388)), thanks to [Daniel Blyth](https://github.com/dblythy).
- Added discardableResult to allow developers to choose whether or not certain functions should return a result ([#385](https://github.com/parse-community/Parse-Swift/pull/385)), thanks to [Damian Van de Kauter](https://github.com/vdkdamian).

__Fixes__
- Ensure properties that are already saved ParseObject's are converted to Parse pointers when using saveAll ([#390](https://github.com/parse-community/Parse-Swift/pull/390)), thanks to [Corey Baker](https://github.com/cbaker6).

### 4.8.0
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/4.7.0...4.8.0)

__New features__
- Add ParseSpotify authentication ([#375](https://github.com/parse-community/Parse-Swift/pull/375)), thanks to [Ulaş Sancak](https://github.com/rocxteady).

__Fixes__
- Encode withinPolygon Queryconstraint correctly ([#381](https://github.com/parse-community/Parse-Swift/pull/381)), thanks to [Corey Baker](https://github.com/cbaker6).
- Use select for ParseLiveQuery when fields are not present ([#376](https://github.com/parse-community/Parse-Swift/pull/376)), thanks to [Corey Baker](https://github.com/cbaker6).

### 4.7.0
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/4.6.0...4.7.0)

__New features__
- Add support for ParseFile and beforeConnect triggers ([#376](https://github.com/parse-community/Parse-Swift/pull/376)), thanks to [Corey Baker](https://github.com/cbaker6).

### 4.6.0
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/4.5.0...4.6.0)

__New features__
- Add the ability to use Parse Hooks and Triggers ([#373](https://github.com/parse-community/Parse-Swift/pull/373)), thanks to [Corey Baker](https://github.com/cbaker6).
- Add ParseInstagram authentication ([#372](https://github.com/parse-community/Parse-Swift/pull/372)), thanks to [Ulaş Sancak](https://github.com/rocxteady).
- Add the ability to send APN and FCM push notifications. Also adds the ability to query _PushStatus ([#371](https://github.com/parse-community/Parse-Swift/pull/371)), thanks to [Corey Baker](https://github.com/cbaker6).
- Add ParseSchema, ParseCLP, and ParseFieldOptions. Should only be used when using the Swift SDK on a secured server ([#370](https://github.com/parse-community/Parse-Swift/pull/370)), thanks to [Corey Baker](https://github.com/cbaker6).

### 4.5.0
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/4.4.0...4.5.0)

__New features__
- Add toCLLocation and toCLLocationCoordinate2D computed properties to ParseGeoPoint, deprecate toCLLocation() and toCLLocationCoordinate2D() ([#366](https://github.com/parse-community/Parse-Swift/pull/366)), thanks to [Corey Baker](https://github.com/cbaker6).
- Add query computed property to ParseObject ([#365](https://github.com/parse-community/Parse-Swift/pull/365)), thanks to [Corey Baker](https://github.com/cbaker6).
- Add macCatalyst to SPM ([#363](https://github.com/parse-community/Parse-Swift/pull/363)), thanks to [Corey Baker](https://github.com/cbaker6).
- Add an order() method to Query that excepts a variadic list as input ([#362](https://github.com/parse-community/Parse-Swift/pull/362)), thanks to [Corey Baker](https://github.com/cbaker6).

__Improvements__
- Allow includeAll key to be sent with additional include keys. When fetching, if the include argument is specified, convert it to a Set to prevent duplicate keys from being sent to the server ([#367](https://github.com/parse-community/Parse-Swift/pull/367)), thanks to [Corey Baker](https://github.com/cbaker6).
- Allow LiveQuery client to be set using ParseLiveQuery.defaultClient and deprecate ParseLiveQuery.setDefault(). Show usage of deprecated code as warnings during compile time and suggest changes ([#360](https://github.com/parse-community/Parse-Swift/pull/360)), thanks to [Corey Baker](https://github.com/cbaker6).

### 4.4.0
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/4.3.1...4.4.0)

__Improvements__
- Drop support for Swift 5.2 as App Store requires apps to be built in Xcode 12 ([#356](https://github.com/parse-community/Parse-Swift/pull/356)), thanks to [Corey Baker](https://github.com/cbaker6).

### 4.3.1
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/4.3.0...4.3.1)

__Fixes__
- Fix links to API documentation ([#354](https://github.com/parse-community/Parse-Swift/pull/354)), thanks to [Corey Baker](https://github.com/cbaker6).

### 4.3.0
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/4.2.0...4.3.0)

__Improvements__
- Use DocC for documentation instead of jazzy. Improved documentation ([#350](https://github.com/parse-community/Parse-Swift/pull/350)), thanks to [Corey Baker](https://github.com/cbaker6).

### 4.2.0
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/4.1.0...4.2.0)

__New features__
- Add variadic QueryConstraint methods for or, nor, and ([#345](https://github.com/parse-community/Parse-Swift/pull/345)), thanks to [Corey Baker](https://github.com/cbaker6).

__Improvements__
- Add clientDefault static property to ParseLiveQuery which replaces the getDefault() method. getDefault() is still avaiable, but will be deprecated in ParseSwift 5.0.0 so it is recommended to switch to defaultClient ([#342](https://github.com/parse-community/Parse-Swift/pull/342)), thanks to [Corey Baker](https://github.com/cbaker6).

### 4.1.0
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/4.0.1...4.1.0)

__Improvements__
- Let the OS and developer decide if app tracking authorization is required when using ParseAnalytics. ParseAnalytics can now take any Codable value in its' dimensions instead of just strings. Added a new property "date" to ParseAnalytics. The "at" property will be deprecated in ParseSwift 5.0.0, so developers should switch to "date". ParseAnalytics can now be properly decoded after encoding with a JSONEncoder. This is useful if ParseAnalytics need to be stored locally and sent to the server later ([#341](https://github.com/parse-community/Parse-Swift/pull/341)), thanks to [Corey Baker](https://github.com/cbaker6).

### 4.0.1
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/4.0.0...4.0.1)

__Fixes__
- Allow ParseRole's to be updated when the SDK is allowing custom objectId's ([#338](https://github.com/parse-community/Parse-Swift/pull/338)), thanks to [Corey Baker](https://github.com/cbaker6).

### 4.0.0
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/3.1.2...4.0.0)

__New features__
- Add the verifyPassword to ParseUser. This method defaults to using POST though POST is not available on the current Parse Server. Change userPost == false to use GET on older Parse Servers ([#333](https://github.com/parse-community/Parse-Swift/pull/333)), thanks to [Corey Baker](https://github.com/cbaker6).
- (Breaking Change) Bump the SPM toolchain from 5.1 to 5.5. This is done to take advantage of features in the latest toolchain. For developers using < Xcode 13 and depending on the Swift SDK through SPM, this will cause a break. You can either upgrade your Xcode or use Cocoapods or Carthage to depend on ParseSwift ([#326](https://github.com/parse-community/Parse-Swift/pull/326)), thanks to [Corey Baker](https://github.com/cbaker6).
- (Breaking Change) Add the ability to merge updated ParseObject's with original objects when using the .mergeable property. To do this, developers need to add an implementation of merge() to respective ParseObject's. The compiler will recommend the new originalData property be added to every ParseObject. If you used ParseObjectMutable in the past, you should remove it as it is now part of ParseObject. In addition, all ParseObject properties should be optional and every object needs to have a default initializer of init(). See the Playgrounds for recommendations on how to define a ParseObject. Look at the PR for details on why this is important when using the SDK ([#315](https://github.com/parse-community/Parse-Swift/pull/315)), thanks to [Corey Baker](https://github.com/cbaker6).
- Add DocC for SDK documentation ([#209](https://github.com/parse-community/Parse-Swift/pull/214)), thanks to [Corey Baker](https://github.com/cbaker6).

__Improvements__
- (Breaking Change) Make ParseRelation conform to Codable and add methods to make decoded stored ParseRelations "usable". ParseObjects can now contain properties of ParseRelation<Self>. In addition, ParseRelations can now be made from ParseObject pointers. For ParseRole, the computed properties: users and roles, are now optional. The queryRoles property has been changed to queryRoles() to improve the handling of thrown errors ([#328](https://github.com/parse-community/Parse-Swift/pull/328)), thanks to [Corey Baker](https://github.com/cbaker6).
- (Breaking Change) Change the following method parameter names: isUsingMongoDB -> usingMongoDB, isIgnoreCustomObjectIdConfig -> ignoringCustomObjectIdConfig, isUsingEQ -> usingEqComparator ([#321](https://github.com/parse-community/Parse-Swift/pull/321)), thanks to [Corey Baker](https://github.com/cbaker6).
- (Breaking Change) Change the following method parameter names: isUsingMongoDB -> usingMongoDB, isIgnoreCustomObjectIdConfig -> ignoringCustomObjectIdConfig, isUsingEQ -> usingEqComparator ([#321](https://github.com/parse-community/Parse-Swift/pull/321)), thanks to [Corey Baker](https://github.com/cbaker6).
- (Breaking Change) Change the following method parameter names: isUsingTransactions -> usingTransactions, isAllowingCustomObjectIds -> allowingCustomObjectIds, isUsingEqualQueryConstraint -> usingEqualQueryConstraint, isMigratingFromObjcSDK -> migratingFromObjcSDK, isDeletingKeychainIfNeeded -> deletingKeychainIfNeeded ([#323](https://github.com/parse-community/Parse-Swift/pull/323)), thanks to [Corey Baker](https://github.com/cbaker6).

__Fixes__
- Async/await methods that return void would no throw errors received from server ([#334](https://github.com/parse-community/Parse-Swift/pull/334)), thanks to [Corey Baker](https://github.com/cbaker6).
- Always check for ParseError first when decoding responses from the server. Before this fix, this could cause issues depending on how calls are made from the Swift SDK ([#332](https://github.com/parse-community/Parse-Swift/pull/332)), thanks to [Corey Baker](https://github.com/cbaker6).

### 3.1.2
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/3.1.1...3.1.2)

__Fixes__
- Allowing building of the Swift SDK for Swift 5.5.0 and 5.5.1 re-enabling builds for Xcode 13.0 and 13.1. Note that async/await functionality is only available for Swift 5.5.2+ and Xcode 13.2+ ([#320](https://github.com/parse-community/Parse-Swift/pull/320)), thanks to [Corey Baker](https://github.com/cbaker6).
- Move the var score: Double? to a protocol named ParseQueryScorable. When developers want to sort by score using a matchesText QueryConstraint, they just conform their ParseObject's to ParseQueryScorable ([#319](https://github.com/parse-community/Parse-Swift/pull/319)), thanks to [Corey Baker](https://github.com/cbaker6).

### 3.1.1
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/3.1.0...3.1.1)

__Fixes__
- Always sort keys when using the ParseEncoder as it can cause issues when trying to save ParseObject's that have children ([#318](https://github.com/parse-community/Parse-Swift/pull/318)), thanks to [Corey Baker](https://github.com/cbaker6).

### 3.1.0
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/3.0.0...3.1.0)

__New features__
- Add the ability to explain MongoDB queries by setting usingMongoDB = true for the respective explain query ([#314](https://github.com/parse-community/Parse-Swift/pull/314)), thanks to [Corey Baker](https://github.com/cbaker6).

### 3.0.0
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/2.5.1...3.0.0)

__New features__
- Adds equalTo QueryConstraint along with ability to change the SDK default behavior of using $eq QueryConstraint parameter or not ([#310](https://github.com/parse-community/Parse-Swift/pull/310)), thanks to [Corey Baker](https://github.com/cbaker6).
- Adds isNull and isNotNull QueryConstraint along with the ability set/forceSet null using ParseOperation ([#308](https://github.com/parse-community/Parse-Swift/pull/308)), thanks to [Corey Baker](https://github.com/cbaker6).
- Adds auth support for GitHub, Google, and LinkedIn ([#307](https://github.com/parse-community/Parse-Swift/pull/307)), thanks to [Corey Baker](https://github.com/cbaker6).
- (Breaking Change) Adds options to matchesText QueryConstraint along with the ability to see matching score. The compiler will recommend the new score property be added to all ParseObjects ([#306](https://github.com/parse-community/Parse-Swift/pull/306)), thanks to [Corey Baker](https://github.com/cbaker6).
- Adds withCount query ([#306](https://github.com/parse-community/Parse-Swift/pull/306)), thanks to [Corey Baker](https://github.com/cbaker6).

__Improvements__
- (Breaking Change) Change boolean configuration parameters to match Swift conventions. The compilor should help with name changes ([#311](https://github.com/parse-community/Parse-Swift/pull/311)), thanks to [Corey Baker](https://github.com/cbaker6).
- Improve QueryWhere by making at a set of QueryConstraint's instead of any array. This dedupes the same constraint when encoding the query; improving the encoding speed when the same constraints are added ([#308](https://github.com/parse-community/Parse-Swift/pull/308)), thanks to [Corey Baker](https://github.com/cbaker6).

### 2.5.1
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/2.5.0...2.5.1)

__Improvements__
- Reduce call sites by having all methods with variadic arguments call their array counterparts ([#301](https://github.com/parse-community/Parse-Swift/pull/301)), thanks to [Corey Baker](https://github.com/cbaker6).

__Fixes__
- Let additional headers accept [AnyHashable: Any] ([#302](https://github.com/parse-community/Parse-Swift/pull/302)), thanks to [Corey Baker](https://github.com/cbaker6).
- Throw .missingObjectId when missing the client detects a missing objectId instead of throwing an .unknown error ([#300](https://github.com/parse-community/Parse-Swift/pull/300)), thanks to [Corey Baker](https://github.com/cbaker6).

### 2.5.0
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/2.4.0...2.5.0)

__New features__
- Added create(), replace(), update(), createAll(), replaceAll(), and updateAll() to ParseObjects. Currently, update() and updateAll() are unavaivalble due to limitations of PATCH on the Parse Server ([#299](https://github.com/parse-community/Parse-Swift/pull/299)), thanks to [Corey Baker](https://github.com/cbaker6).
- Added convenience methods to convert ParseObject's to Pointer<ParseObject>'s for QueryConstraint's: !=, containedIn, notContainedIn, containedBy, containsAll ([#298](https://github.com/parse-community/Parse-Swift/pull/298)), thanks to [Corey Baker](https://github.com/cbaker6).

### 2.4.0
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/2.3.1...2.4.0)

__New features__
- Added additional methods to ParseRelation to make it easier to create and query relations ([#294](https://github.com/parse-community/Parse-Swift/pull/294)), thanks to [Corey Baker](https://github.com/cbaker6).
- Enable async/await for iOS13, tvOS13, watchOS6, and macOS10_15. All async/await methods are MainActor's. Requires Xcode 13.2 or above to use async/await. Not compatible with Xcode 13.0/1, will need to upgrade to 13.2+. Still works with Xcode 11/12 ([#278](https://github.com/parse-community/Parse-Swift/pull/278)), thanks to [Corey Baker](https://github.com/cbaker6).

__Fixes__
- When transactions are enabled errors are now thrown from the client if the amount of objects in a transaction exceeds the batch size. An error will also be thrown if a developer attempts to save objects in a transation that has unsaved children ([#295](https://github.com/parse-community/Parse-Swift/pull/294)), thanks to [Corey Baker](https://github.com/cbaker6).

### 2.3.1
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/2.3.0...2.3.1)

__Fixes__
- Fixed an issue where querying an object did not dispatch to the proper queue which can cause app crashes ([#293](https://github.com/parse-community/Parse-Swift/pull/293)), thanks to [Corey Baker](https://github.com/cbaker6).

### 2.3.0
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/2.2.6...2.3.0)

__New features__
- Add a retry mechanism to the SDK that randomly (up to 3 seconds each) tries to reconnect up to 5 times. The developer can increase or reduce the amount of retries when configuring the SDK ([#291](https://github.com/parse-community/Parse-Swift/pull/291)), thanks to [Corey Baker](https://github.com/cbaker6).
- Add toCLLocation and toCLLocationCoordinate2D methods for easy conversion from a ParseGeoPoint object ([#287](https://github.com/parse-community/Parse-Swift/pull/287)), thanks to [Jayson Ng](https://github.com/jaysonng).

__Fixes__
- Fixed an issue where an annonymous could not be turned into a regular user using signup ([#291](https://github.com/parse-community/Parse-Swift/pull/291)), thanks to [Corey Baker](https://github.com/cbaker6).
- The default ACL is now deleted from the keychain when a user is logged out. This previously caused an issue when logging out a user and logging in as a different user caused all objects to only have ACL permisions for the logged in user ([#291](https://github.com/parse-community/Parse-Swift/pull/291)), thanks to [Corey Baker](https://github.com/cbaker6).

### 2.2.6
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/2.2.5...2.2.6)

__Fixes__
- Use default ACL automatically on newley created ParseObject's if a default ACL is available ([#284](https://github.com/parse-community/Parse-Swift/pull/284)), thanks to [Corey Baker](https://github.com/cbaker6).

### 2.2.5
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/2.2.4...2.2.5)

__Fixes__
- Overload QueryConstraint to accept Pointer<ParseObject> ([#281](https://github.com/parse-community/Parse-Swift/pull/281)), thanks to [Corey Baker](https://github.com/cbaker6).
- Add checks to build for Windows ([#281](https://github.com/parse-community/Parse-Swift/pull/281)), thanks to [Corey Baker](https://github.com/cbaker6).

### 2.2.4
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/2.2.3...2.2.4)

__Fixes__
- Delete all stored Parse data and cache when isDeletingKeychainIfNeeded is true ([#280](https://github.com/parse-community/Parse-Swift/pull/280)), thanks to [Corey Baker](https://github.com/cbaker6).

### 2.2.3
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/2.2.2...2.2.3)

__Fixes__
- Improve dpcumentation ([#276](https://github.com/parse-community/Parse-Swift/pull/276)), thanks to [Corey Baker](https://github.com/cbaker6).

### 2.2.2
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/2.2.1...2.2.2)

__Fixes__
- Improve equatable comparison of QueryConstraint ([#275](https://github.com/parse-community/Parse-Swift/pull/275)), thanks to [Corey Baker](https://github.com/cbaker6).

### 2.2.1
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/2.2.0...2.2.1)

__Fixes__
- Set the default cache policy for ParseFile to the default policy set when initializing the SDK ([#274](https://github.com/parse-community/Parse-Swift/pull/274)), thanks to [Corey Baker](https://github.com/cbaker6).

### 2.2.0
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/2.1.0...2.2.0)

__Improvements__
- Added ability to fetch ParsePointer using async/await ([#271](https://github.com/parse-community/Parse-Swift/pull/271)), thanks to [Corey Baker](https://github.com/cbaker6).

__Fixes__
- By default, do not use cache when fetching ParseObject's and ParseFile's. Developers can choose to fetch from cache if desired by passing the necessary option while fetching. Fixed a bug when the incorrect file location for a dowloaded ParseFile was being cached ([#272](https://github.com/parse-community/Parse-Swift/pull/272)), thanks to [Corey Baker](https://github.com/cbaker6).

### 2.1.0
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/2.0.3...2.1.0)

__Improvements__
- Make ParseUser.current, ParseInstallation.current, ParseConfig.current immutable. This prevents accidently setting to nil. When developers want to make changes, they should make mutable copies, mutate, then save ([#266](https://github.com/parse-community/Parse-Swift/pull/266)), thanks to [Corey Baker](https://github.com/cbaker6).
- Added the ParseObjectMutable protocol to make emptyObject more developer friendly ([#270](https://github.com/parse-community/Parse-Swift/pull/270)), thanks to [Damian Van de Kauter](https://github.com/novemTeam).


### 2.0.3
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/2.0.2...2.0.3)

__Fixes__
- Async/await methods should be available for watchOS 8+ ([#265](https://github.com/parse-community/Parse-Swift/pull/265)), thanks to [Corey Baker](https://github.com/cbaker6).

### 2.0.2
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/2.0.1...2.0.2)

__Improvements__
- Add static methods for accessing encoders/decoder so developers do not have to create instances to access ([#259](https://github.com/parse-community/Parse-Swift/pull/259)), thanks to [Corey Baker](https://github.com/cbaker6).

__Fixes__
- Parse ViewModels always dispatch to the main queue when updating published properties. This prevents possible issues when background async calls update properties used for views ([#260](https://github.com/parse-community/Parse-Swift/pull/260)), thanks to [Corey Baker](https://github.com/cbaker6).

### 2.0.1
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/2.0.0...2.0.1)

__Fixes__
- ParseUser should only encode email when User.current?.email is different from current user email ([#256](https://github.com/parse-community/Parse-Swift/pull/256)), thanks to [Corey Baker](https://github.com/cbaker6).

### 2.0.0
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.11.0...2.0.0)

__New features__
- Added option to delete Parse items from Keychain when the app is running for the first time  ([#254](https://github.com/parse-community/Parse-Swift/pull/254)), thanks to [Corey Baker](https://github.com/cbaker6).

__Improvements__
- (Breaking Change) ParseObject's now conform to Identifiable and can be used directly with SwiftUI without additonal properties needed. Drops support for iOS 12, tvOS 12, watchOS 5, and macOS 10.13/14 ([#254](https://github.com/parse-community/Parse-Swift/pull/254)), thanks to [Corey Baker](https://github.com/cbaker6).

### 1.11.0
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.10.4...1.11.0)

__Improvements__
- Added `operation` for `set` and `forceSet`, used for single key updates ([#248](https://github.com/parse-community/Parse-Swift/pull/248)), thanks to [Daniel Blyth](https://github.com/dblythy) and [Corey Baker](https://github.com/cbaker6).
- Add more detail to invalid struct errors ([#238](https://github.com/parse-community/Parse-Swift/pull/238)), thanks to [Daniel Blyth](https://github.com/dblythy).

### 1.10.4
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.10.3...1.10.4)

__Improvements__
- Improve documentation for ParseObject ([#253](https://github.com/parse-community/Parse-Swift/pull/253)), thanks to [Corey Baker](https://github.com/cbaker6).

### 1.10.3
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.10.2...1.10.3)

__Improvements__
- Update documents to show new Swift 5.5 async/await methods ([#252](https://github.com/parse-community/Parse-Swift/pull/252)), thanks to [Corey Baker](https://github.com/cbaker6).

### 1.10.2
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.10.1...1.10.2)

__New features__
- Supports Swift 5.5 async/await ([#212](https://github.com/parse-community/Parse-Swift/pull/212)), thanks to [Corey Baker](https://github.com/cbaker6).

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
- ParseUser should not send email if it has not been modified or else email verification is resent ([#241](https://github.com/parse-community/Parse-Swift/pull/241)), thanks to [Corey Baker](https://github.com/cbaker6).

### 1.9.10
[Full Changelog](https://github.com/parse-community/Parse-Swift/compare/1.9.9...1.9.10)

__Fixes__
- ParseInstallation cannot be retreived from Keychain after the first fun ([#236](https://github.com/parse-community/Parse-Swift/pull/236)), thanks to [Corey Baker](https://github.com/cbaker6).

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
- Properly allow a mixed custom objectId environment without compromising safety checks using .save(). If a developer wants to ignore the objectId checks, they need to specify ignoringCustomObjectIdConfig = true each time ([#222](https://github.com/parse-community/Parse-Swift/pull/222)), thanks to [Corey Baker](https://github.com/cbaker6).

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
- Setting limit = 0 of a query does not query the server and instead just returns empty or no results depending on the query ([#189](https://github.com/parse-community/Parse-Swift/pull/189)), thanks to [Corey Baker](https://github.com/cbaker6).
- ParseGeoPoint initializer now throws if geopoints are out-of-bounds instead of asserting ([#190](https://github.com/parse-community/Parse-Swift/pull/190)), thanks to [Corey Baker](https://github.com/cbaker6).
- Persist all properties of ParseUser and ParseInstallation to keychain so they can be accessed via current. Developers do not have to fetch the ParseUser or ParseInstlation after app restart anymore ([#191](https://github.com/parse-community/Parse-Swift/pull/191)), thanks to [Corey Baker](https://github.com/cbaker6).

__Fixes__
- Fixed a bug when signing up from a ParseUser instance resulted in custom keys not being persisted to the keychain ([#187](https://github.com/parse-community/Parse-Swift/pull/187)), thanks to [Corey Baker](https://github.com/cbaker6).
- Fixed a bug where countExplain query result was not returned as an array  ([#189](https://github.com/parse-community/Parse-Swift/pull/189)), thanks to [Corey Baker](https://github.com/cbaker6).
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
- Transactions currently do not work when using MongoDB(postgres does work) on the parse-server. Internal use of transactions are disabled by default. If you want the Swift SDK to use transactions internally, you need to set isUsingTransactionsInternally=true when configuring the client. It is recommended not to use transactions if you are using MongoDB until it is fixed on the server ([#158](https://github.com/parse-community/Parse-Swift/pull/158)), thanks to [Corey Baker](https://github.com/cbaker6).

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
- ParseFiles cannot be updated from the client and will now throw an error if attempted. Instead another file should be created and the older file should be deleted by the developer. ([#144](https://github.com/parse-community/Parse-Swift/pull/144)), thanks to [Corey Baker](https://github.com/cbaker6).
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
- (Breaking Change) Aggregrate takes any Encodable type. Query planning methods are now: findExlpain, firstEplain, countExplain, etc. The distinct query now works. The client will also not throw an error anymore when attempting to delete a File and the masterKey is not available. The developer will still need to configure the server to delete the file properly ([#122](https://github.com/parse-community/Parse-Swift/pull/122)), thanks to [Corey Baker](https://github.com/cbaker6).

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
- There was another bug after a user first logs in anonymously and then becomes a real user. The authData sent to the server was not stripped, keep the user anonymous instead of making them a real user ([#100](https://github.com/parse-community/Parse-Swift/pull/100)), thanks to [Corey Baker](https://github.com/cbaker6).

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
- Parse server supports `$eq`, but this is not supported by LiveQueryServer, switched to supported ([#49](https://github.com/parse-community/Parse-Swift/pull/49)), thanks to [Corey Baker](https://github.com/cbaker6).
- Bug when updating a ParseObject bug where objects was accidently converted to pointers ([#48](https://github.com/parse-community/Parse-Swift/pull/48)), thanks to [Corey Baker](https://github.com/cbaker6).
- User logout was calling the wrong endpoint ([#43](https://github.com/parse-community/Parse-Swift/pull/43)), thanks to [Corey Baker](https://github.com/cbaker6) and [Tom Fox](https://github.com/TomWFox).
- Fix an issue where ACL was overwritten with nil ([#40](https://github.com/parse-community/Parse-Swift/pull/40)), thanks to [Corey Baker](https://github.com/cbaker6).
- Update Keychain during fetch. Fix synchronous bug that occured with `ParseError` was thrown ([#38](https://github.com/parse-community/Parse-Swift/pull/38)), thanks to [Corey Baker](https://github.com/cbaker6).
- Fix ParseEncoder bugs ([#27](https://github.com/parse-community/Parse-Swift/pull/27)), thanks to [Corey Baker](https://github.com/cbaker6).
- Fix async callback queue bug ([#27](https://github.com/parse-community/Parse-Swift/pull/27)), thanks to [Corey Baker](https://github.com/cbaker6).
- Fix bugs in ParseACL and bump minimum OS support to `.iOS(.v11), .macOS(.v10_13), .tvOS(.v11), .watchOS(.v4)` ([#19](https://github.com/parse-community/Parse-Swift/pull/19)), thanks to [Corey Baker](https://github.com/cbaker6).
- Fix bugs in batch and save responses ([#15](https://github.com/parse-community/Parse-Swift/pull/15)), thanks to [Corey Baker](https://github.com/cbaker6).
- Fix Keychain tests ([#12](https://github.com/parse-community/Parse-Swift/pull/12)), thanks to [Corey Baker](https://github.com/cbaker6).
