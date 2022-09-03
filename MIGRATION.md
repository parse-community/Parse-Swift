# Migration from Parse ObjC SDK <!-- omit in toc -->

This document describes how to migrate from the [Parse ObjC SDK](https://github.com/parse-community/Parse-SDK-iOS-OSX) to the Parse Swift SDK.

ℹ️ *This document is a work-in-progress. If you find information missing, please submit a pull request to help us updating this document for the benefit of others.*

- [Status of the SDKs](#status-of-the-sdks)
- [Migration Instructions](#migration-instructions)
- [Behavioral Differences](#behavioral-differences)
- [Known Issues](#known-issues)
- [Feature Comparison](#feature-comparison)

# Status of the SDKs

The Parse ObjC SDK will be phased out in the future in favor of the more modern Parse Swift SDK. While both SDKs overlap in the ecosystems they serve, they are built conceptually different, which can make migration more challenging. Your milage may vary depending on your use case, we therefore encourage you to consider migrating as soon as possible.

# Migration Instructions

1. x
2. x
3. x

# Behavioral Differences

- x
- x
- x

# Known Issues

The issues below are important to consider before migrating.

- ⚠️ Partially updating an object sends the complete object (including unchanged properties) to the server if you follow the familiar syntax from the Parse ObjC SDK or any other Parse SDK. This can have a significant impact on data transfer costs depending on your use case and architecture. All other Parse SDKs, including the Parse ObjC SDK, only send the changed properties to the server. The Parse Swift SDK requires a different syntax with additional overhead to achieve the same behavior. For details see [GitHub issue #242](https://github.com/parse-community/Parse-Swift/issues/242).

  <details>
    <summary>Code Examples</summary>
  
    ```swift
    // The following examples compare how to update a saved object in the Parse ObjC SDK
    // vs. the Parse Swift SDK. For simplicity, the examples use synchonrous methods.

    // Parse ObjC SDK
    PFObject *obj = [PFObject objectWithClassName:@"Example"];
    obj[@"key"] = @"value1";
    [obj save];
    obj[@"key"] = @"value2";
    [obj save];

    // Parse Swift SDK - Variant 1
    // This sends the complete object to the server when partially updating the object. This approach
    // is not recommended as sending unchanged properties is unnecessary and therefore wastes resources.
    struct Example: ParseObject {
      var objectId: String?
      var createdAt: Date?
      var updatedAt: Date?
      var ACL: ParseACL?
      var originalData: Data? 
      var key: String?
    }

    let obj = Example()
    obj.key = "value1"
    obj.save()
    obj.key = "value2"
    obj.save()

    // Parse Swift SDK - Variant 2
    // This sends only the changed properties to the server. Note that `objMergable` only contains the
    // modified properties and is missing the unchanged properties. To also contain the unchanged
    // properties in addition to the changed properties, an additional `fetch` call on the respective
    // object would be necessary. This aproach is not recommended as it adds an additional server
    // request to get data that is already present locally. This is unrelated to the limitation that
    // any Parse SDK is unaware of any object modification that is done via Cloud Code triggers.
    struct Example: ParseObject {
      var objectId: String?
      var createdAt: Date?
      var updatedAt: Date?
      var ACL: ParseACL?
      var originalData: Data? 
      var key: String?
    }

    let obj = Example()
    obj.key = "value1"
    obj.save()
    var objMergable = obj.mergeable
    objMergable.key = "value2"
    objMergable.save()

    // Parse Swift SDK - Variant 3
    // This sends only the changed properties to the server. By overriding the `merge` method the
    // `objMergable` also contains the unchanged properties of the original `obj`. This means no
    // additional `fetch` call is needed. This is the recommned approach which corresponds the most
    // with the behavior of the Parse ObjC SDK. Note that any change of custom properies will need
    // to reflect in the `merge` method, otherwise `objMergable` may only partially contain the
    // original data which leads to data inconsistencies that may be difficult to track down.
    struct Example: ParseObject {
      var objectId: String?
      var createdAt: Date?
      var updatedAt: Date?
      var ACL: ParseACL?
      var originalData: Data? 
      var key: String?

      func merge(with object: Self) throws -> Self { 
        var updated = try mergeParse(with: object) 
        if updated.shouldRestoreKey(\.key, original: object) { 
          updated.key = object.key 
        }
        return updated
      }
    }

    let obj = Example()
    obj.key = "value1"
    obj.save()
    var objMergable = obj.mergeable
    objMergable.key = "value2"
    objMergable.save()
    ```
  </details>

# Feature Comparison

This table only lists features that are known to be available in the Parse ObjC SDK but still missing in the Swift SDK. *This table is a work-in-progress.*

| Feature | Parse ObjC SDK | Parse Swift SDK |
|---------|----------------|-----------------|
| -       | -              | -               |
