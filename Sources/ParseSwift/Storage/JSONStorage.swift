//
//  JSONStorage.swift
//  ParseSwift
//
//  Created by Daniel Blyth on 21/10/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation
struct JSONStorage {
    public static var store: [String: [String: AnyObject]] = [:]
    static func put<T>(object: T) where T: ParseObject {
        do {
            let encoded = try ParseCoding.jsonEncoder().encode(object)
            if let objectId = object.objectId,
               let json = try JSONSerialization.jsonObject(with: encoded, options: []) as? [String: AnyObject] {
                store[objectId] = json
            }
        } catch {
            print("Could not store object")
        }
    }
    static func put<T>(objects: [T]) where T: ParseObject {
        for parseObject in objects {
            put(object: parseObject)
        }
    }
    static func getEncodedKeys(object: ParseType) -> Set<String> {
        var keysToSkip: Set<String>!
        if !ParseSwift.configuration.allowCustomObjectId {
            keysToSkip = ParseEncoder.SkipKeys.object.keys()
        } else {
            keysToSkip = ParseEncoder.SkipKeys.customObjectId.keys()
        }
        guard let objectable = object as? Objectable else {
            return keysToSkip
        }
        do {
            let encoded = try ParseCoding.parseEncoder().encode(object)
            if let id = objectable.objectId,
               let previousStore = store[id],
               let json = try JSONSerialization.jsonObject(with: encoded, options: []) as? [String: AnyObject] {
                for keyName in json.keys where
                (json[keyName] as? NSObject) == (previousStore[keyName] as? NSObject)
                && !keysToSkip.contains(keyName) {
                    keysToSkip.insert(keyName)
                }
            }
        }
    } catch {
        
    }
    return keysToSkip
}

}
