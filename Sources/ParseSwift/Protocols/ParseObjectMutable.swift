//
//  ParseObjectMutable.swift
//  ParseSwift
//
//  Created by Damian Van de Kauter on 30/10/2021.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

/**
 The `ParseObjectMutable` protocol creates an empty copy of the respective object.
 This can be used when you only need to update a subset of the fields of an object
 as oppose to updating every field of an object.
 Using the mutable copy and updating a subset of the fields reduces the amount of data
 sent between client and server when using `save` and `saveAll`
 to update objects.
 
 **Example use case for `ParseUser`:**
 ````
 struct User: ParseUser, ParseObjectMutable {
     //: These are required by `ParseObject`.
     var objectId: String?
     var createdAt: Date?
     var updatedAt: Date?
     var ACL: ParseACL?

     //: These are required by `ParseUser`.
     var username: String?
     var email: String?
     var emailVerified: Bool?
     var password: String?
     var authData: [String: [String: String]?]?

     //: Your custom keys.
     var customKey: String?
     var score: GameScore?
     var targetScore: GameScore?
     var allScores: [GameScore]?
 }
 
 var user = User.current?.mutable
 user?.customKey = "newValue"

 do {
     try await user?.save()
 } catch {
     // Handle error
 }
 ````
 
 **Example use case for a general `ParseObject`:**
 ````
 struct GameScore: ParseObject, ParseObjectMutable {
     //: These are required by ParseObject
     var objectId: String?
     var createdAt: Date?
     var updatedAt: Date?
     var ACL: ParseACL?

     //: Your own properties.
     var score: Int = 0
 }
 //: It's recommended to place custom initializers in an extension
 //: to preserve the convenience initializer.
 extension GameScore {
   
     init(score: Int) {
         self.score = score
     }
   
     init(objectId: String?) {
         self.objectId = objectId
     }
 }
 
 var newScore = GameScore(score: 10).mutable
 newScore.score = 200
 
 do {
     try await newScore.save()
 } catch {
     // Handle error
 }
 ````

 - warning: Using the `ParseObjectMutable` protocol requires the developer to
 initialize all of the `ParseObject` properties. This can be accomplished by making all properties
 optional or setting default values for non-optional properties.
 This also allows your objects to be used as Parse `Pointer`‘s.
 It's recommended to place custom initializers in an extension
 to preserve the convenience initializer.
*/
public protocol ParseObjectMutable: ParseObject {
    init()

    /**
     An empty copy of the respective object that allows you to update a
     a subset of the fields of an object as oppose to updating every field of an object.
     - note: It is recommended to use this to create a mutable copy of your `ParseObject`.
    */
    var mutable: Self { get }
}

public extension ParseObjectMutable {
    var mutable: Self {
        var object = Self()
        object.objectId = objectId
        object.createdAt = createdAt
        return object
    }
}
