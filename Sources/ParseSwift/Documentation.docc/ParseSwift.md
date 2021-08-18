# ``ParseSwift``
A pure Swift library that gives you access to the powerful Parse Server backend from your Swift applications.

## Overview
![Parse logo](parse.png)
For more information about the Parse Platform and its features, see the public [documentation][docs]. The ParseSwift SDK is not a port of the [Parse-SDK-iOS-OSX SDK](https://github.com/parse-community/Parse-SDK-iOS-OSX) and though some of it may feel familiar, it is not backwards compatible and is designed with a new philosophy. For more details visit the [api documentation](http://parseplatform.org/Parse-Swift/api/).

To learn how to use or experiment with ParseSwift, you can run and edit the [ParseSwift.playground](https://github.com/parse-community/Parse-Swift/tree/main/ParseSwift.playground/Pages). You can use the parse-server in [this repo](https://github.com/netreconlab/parse-hipaa/tree/parse-swift) which has docker compose files (`docker-compose up` gives you a working server) configured to connect with the playground files, has [Parse Dashboard](https://github.com/parse-community/parse-dashboard), and can be used with mongoDB or PostgreSQL.

## Topics

### Initialize the SDK

- ``ParseSwift/ParseSwift/initialize(configuration:migrateFromObjcSDK:)``
- ``ParseSwift/ParseSwift/initialize(applicationId:clientKey:masterKey:serverURL:liveQueryServerURL:allowCustomObjectId:useTransactionsInternally:keyValueStore:requestCachePolicy:cacheMemoryCapacity:cacheDiskCapacity:httpAdditionalHeaders:migrateFromObjcSDK:authentication:)``

