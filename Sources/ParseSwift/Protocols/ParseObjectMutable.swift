//
//  ParseObjectMutable.swift
//  ParseSwift
//
//  Created by Damian Van de Kauter on 30/10/2021.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

/**
 The **ParseObjectMutable** protocol adds an empty version of the respective object. This can be used when you only need to update a
 a subset of the fields of an object as oppose to updating every field of an object. Using an empty object and updating
 a subset of the fields reduces the amount of data sent between client and server when using `save` and `saveAll`
 to update objects.
 
 **Example use case:**
    ~~~~
    var user = User.current?.mutable
    user?.customKey = "newValue"

    do {
        try await user?.save()
    } catch {
        // Handle error
    }
    ~~~~

 - warning: Using the **ParseObjectMutable** protocol requires the developer to use an **init()** without declaring custom properties.
 You can still use non-optional properties if you add them to your **init()** method and give them a default value.
 If you need a custom **init()**, you can't use the **ParseObjectMutable** protocol.
*/
public protocol ParseObjectMutable: ParseObject {
    init()

    var mutable: Self { get }
}

public extension ParseObjectMutable {

    /**
     An empty version of the respective object that allows you to update a
     a subset of the fields of an object as oppose to updating every field of an object.
     - note: You need to use this to create a mutable copy of your **ParseObject**.
    */
    var mutable: Self {
        var object = self
        object.objectId = objectId
        object.createdAt = createdAt
        return object
    }
}

/**
 The **ParseInstallationMutable** protocol adds an empty version of the respective object. This can be used when you only need to update a
 a subset of the fields of an object as oppose to updating every field of an object. Using an empty object and updating
 a subset of the fields reduces the amount of data sent between client and server when using `save` and `saveAll`
 to update objects.
 
 It combines the **ParseInstallation** protocol and the **ParseObjectMutable** protocol.
*/
public protocol ParseInstallationMutable: ParseInstallation, ParseObjectMutable {
    init()
}

/**
 The **ParseUserMutable** protocol adds an empty version of the respective object. This can be used when you only need to update a
 a subset of the fields of an object as oppose to updating every field of an object. Using an empty object and updating
 a subset of the fields reduces the amount of data sent between client and server when using `save` and `saveAll`
 to update objects.
 
 It combines the **ParseUser** protocol and the **ParseObjectMutable** protocol.
*/
public protocol ParseUserMutable: ParseUser, ParseObjectMutable {
    init()
}
