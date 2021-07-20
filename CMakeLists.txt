cmake_minimum_required(VERSION 3.16)

project(ParseSwift LANGUAGES C Swift)

set(CMAKE_Swift_MODULE_DIRECTORY ${CMAKE_BINARY_DIR}/swift)

add_library(ParseSwift SHARED

    Sources/ParseSwift/API/API+Commands.swift
    Sources/ParseSwift/API/API.swift
    Sources/ParseSwift/API/BatchUtils.swift
    Sources/ParseSwift/API/ParseURLSessionDelegate.swift
    Sources/ParseSwift/API/Responses.swift
    Sources/ParseSwift/API/URLSession+extensions.swift
    Sources/ParseSwift/Authentication/3rd Party
    Sources/ParseSwift/Authentication/3rd Party/ParseApple.swift
    Sources/ParseSwift/Authentication/3rd Party/ParseFacebook.swift
    Sources/ParseSwift/Authentication/3rd Party/ParseLDAP.swift
    Sources/ParseSwift/Authentication/3rd Party/ParseTwitter.swift
    Sources/ParseSwift/Authentication/Internal
    Sources/ParseSwift/Authentication/Internal/ParseAnonymous.swift
    Sources/ParseSwift/Authentication/Protocols
    Sources/ParseSwift/Authentication/Protocols/ParseAuthentication+combine.swift
    Sources/ParseSwift/Authentication/Protocols/ParseAuthentication.swift
    Sources/ParseSwift/Coding/AnyCodable.swift
    Sources/ParseSwift/Coding/AnyDecodable.swift
    Sources/ParseSwift/Coding/AnyEncodable.swift
    Sources/ParseSwift/Coding/Extensions.swift
    Sources/ParseSwift/Coding/ParseCoding.swift
    Sources/ParseSwift/Coding/ParseEncoder.swift
    Sources/ParseSwift/Internal/BaseConfig.swift
    Sources/ParseSwift/Internal/BaseParseInstallation.swift
    Sources/ParseSwift/Internal/BaseParseUser.swift
    Sources/ParseSwift/Internal/Data+hexString.swift
    Sources/ParseSwift/Internal/NoBody.swift
    Sources/ParseSwift/Internal/ParseHash.swift
    Sources/ParseSwift/LiveQuery/LiveQuerySocket.swift
    Sources/ParseSwift/LiveQuery/Messages.swift
    Sources/ParseSwift/LiveQuery/Operations.swift
    Sources/ParseSwift/LiveQuery/ParseLiveQuery.swift
    Sources/ParseSwift/LiveQuery/ParseLiveQueryConstants.swift
    Sources/ParseSwift/LiveQuery/Protocols
    Sources/ParseSwift/LiveQuery/Protocols/LiveQuerySocketDelegate.swift
    Sources/ParseSwift/LiveQuery/Protocols/LiveQueryable.swift
    Sources/ParseSwift/LiveQuery/Protocols/ParseLiveQueryDelegate.swift
    Sources/ParseSwift/LiveQuery/Protocols/ParseSubscription.swift
    Sources/ParseSwift/LiveQuery/Subscription.swift
    Sources/ParseSwift/LiveQuery/SubscriptionCallback.swift
    Sources/ParseSwift/Objects/ParseInstallation+combine.swift
    Sources/ParseSwift/Objects/ParseInstallation.swift
    Sources/ParseSwift/Objects/ParseObject+combine.swift
    Sources/ParseSwift/Objects/ParseObject.swift
    Sources/ParseSwift/Objects/ParseRole.swift
    Sources/ParseSwift/Objects/ParseSession.swift
    Sources/ParseSwift/Objects/ParseUser+combine.swift
    Sources/ParseSwift/Objects/ParseUser.swift
    Sources/ParseSwift/Operations/Add.swift
    Sources/ParseSwift/Operations/AddRelation.swift
    Sources/ParseSwift/Operations/AddUnique.swift
    Sources/ParseSwift/Operations/Delete.swift
    Sources/ParseSwift/Operations/Increment.swift
    Sources/ParseSwift/Operations/ParseOperation+combine.swift
    Sources/ParseSwift/Operations/ParseOperation.swift
    Sources/ParseSwift/Operations/Remove.swift
    Sources/ParseSwift/Operations/RemoveRelation.swift
    Sources/ParseSwift/Parse.swift
    Sources/ParseSwift/ParseConstants.swift
    Sources/ParseSwift/Protocols/Deletable.swift
    Sources/ParseSwift/Protocols/Fetchable.swift
    Sources/ParseSwift/Protocols/Fileable.swift
    Sources/ParseSwift/Protocols/LocallyIdentifiable.swift
    Sources/ParseSwift/Protocols/Objectable.swift
    Sources/ParseSwift/Protocols/ParseType.swift
    Sources/ParseSwift/Protocols/Queryable.swift
    Sources/ParseSwift/Protocols/Savable.swift
    Sources/ParseSwift/Storage/KeychainStore.swift
    Sources/ParseSwift/Storage/ParseFileManager.swift
    Sources/ParseSwift/Storage/ParseKeyValueStore.swift
    Sources/ParseSwift/Storage/ParseStorage.swift
    Sources/ParseSwift/Storage/SecureStorage.swift
    Sources/ParseSwift/Types/ParseACL.swift
    Sources/ParseSwift/Types/ParseCloud+combine.swift
    Sources/ParseSwift/Types/ParseCloud.swift
    Sources/ParseSwift/Types/ParseConfig+combine.swift
    Sources/ParseSwift/Types/ParseConfig.swift
    Sources/ParseSwift/Types/ParseError.swift
    Sources/ParseSwift/Types/ParseFile+combine.swift
    Sources/ParseSwift/Types/ParseFile.swift
    Sources/ParseSwift/Types/ParseGeoPoint.swift
    Sources/ParseSwift/Types/ParseHealth+Combine.swift
    Sources/ParseSwift/Types/ParseHealth.swift
    Sources/ParseSwift/Types/ParseRelation.swift
    Sources/ParseSwift/Types/Pointer.swift
    Sources/ParseSwift/Types/Query+combine.swift
    Sources/ParseSwift/Types/Query.swift

    )

set_target_properties(ParseSwift PROPERTIES
  INTERFACE_LINK_DIRECTORIES $<TARGET_LINKER_FILE_DIR:ParseSwift>
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_Swift_MODULE_DIRECTORY})

add_subdirectory(swift-jni)
target_link_libraries(ParseSwift PUBLIC JNI)

add_subdirectory(SDL)
target_link_libraries(ParseSwift PUBLIC SDL)

# target_compile_options(ParseSwift PRIVATE
#        $<$<BOOL:ENABLE_TESTING>:-enable-testing>)

# install(TARGETS ParseSwift LIBRARY DESTINATION lib)
