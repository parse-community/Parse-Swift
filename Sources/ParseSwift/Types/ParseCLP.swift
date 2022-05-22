//
//  ParseCLP.swift
//  ParseSwift
//
//  Created by Corey Baker on 5/21/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

public struct ParseCLP: Codable, Equatable {

    var get: [String: Bool]?
    var find: [String: Bool]?
    var count: [String: Bool]?
    var create: [String: Bool]?
    var update: [String: Bool]?
    var delete: [String: Bool]?
    var addField: [String: Bool]?
    var protectedFields: [String: [String]]?
    var readUserFields: [String]?
    var writeUserFields: [String]?

    enum Access: String, Codable {
        case requiresAuthentication
        case publicScope = "*"
    }

    /*
    func setAccess<W>(_ key: WritableKeyPath<Self, W?>,
                      userObjectId: String, allowed: Bool) -> Self where W: Codable {
        var mutableCLP = self
        mutableCLP[keyPath: key] = [userObjectId: allowed]
        return mutableCLP
    } */
}

func toRole<R>(role: R) throws -> String where R: ParseRole {
    guard let name = role.name else {
        throw ParseError(code: .unknownError, message: "Name of ParseRole cannot be nil")
    }
    return "role:\(name)"
}

// MARK: Protected
public extension ParseCLP {

    internal func getProtected(access: String) -> [String] {
        protectedFields?[access] ?? []
    }

    /**
     Get the protected fields for the given user objectId.
     
     - parameter userObjectId: The user objectId access to check.
     - returns: The protected fields.
    */
    func getProtected(_ userObjectId: String) -> [String] {
        getProtected(access: userObjectId)
    }

    /**
     Get the protected fields for the given user objectId.
     
     - parameter user: The `ParseUser` access to check.
     - returns: The protected fields.
    */
    func getProtected<U>(_ user: U) throws -> [String] where U: ParseUser {
        let userPointer = try user.toPointer()
        return getProtected(access: userPointer.objectId)
    }

    /**
     Get the protected fields for the given user objectId.
     
     - parameter user: The `ParseUser` access to check.
     - returns: The protected fields.
    */
    func getProtected<R>(_ role: R) throws -> [String] where R: ParseRole {
        let roleAccess = try toRole(role: role)
        return getProtected(access: roleAccess)
    }

    internal func setProtected(_ fields: [String], access: String) -> Self {
        var mutableCLP = self
        mutableCLP.protectedFields = [access: fields]
        return mutableCLP
    }

    /**
     Set whether the given user objectId is allowed to retrieve fields from this class.
     
     - parameter userObjectId: The user objectId to provide/restrict access to.
     - parameter fields: The fields to be protected.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setProtected(_ fields: [String], userObjectId: String) -> Self {
        setProtected(fields, access: userObjectId)
    }

    /**
     Set whether the given `ParseUser` is allowed to retrieve fields from this class.
     
     - parameter user: The `ParseUser` to provide/restrict access to.
     - parameter fields: The fields to be protected.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setProtected<U>(_ fields: [String], user: U) throws -> Self where U: ParseUser {
        let userPointer = try user.toPointer()
        return setProtected(fields, access: userPointer.objectId)
    }

    /**
     Set whether the given `ParseRole` is allowed to retrieve fields from this class.
     
     - parameter user: The `ParseRole` to provide/restrict access to.
     - parameter fields: The fields to be protected.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setProtected<R>(_ fields: [String], role: R) throws -> Self where R: ParseRole {
        let roleAccess = try toRole(role: role)
        return setProtected(fields, access: roleAccess)
    }
}

// MARK: WriteUserFields
public extension ParseCLP {

    /**
     Sets permission for the user pointer fields or create/delete/update/addField operations.

     - parameter fields: User pointer fields.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setWriteUser(_ fields: [String]) -> Self {
        var mutableCLP = self
        mutableCLP.writeUserFields = fields
        return mutableCLP
    }
}

// MARK: ReadUserFields
public extension ParseCLP {

    /**
     Sets permission for the user pointer fields or get/count/find operations.

     - parameter fields: User pointer fields.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setReadUser(_ fields: [String]) -> Self {
        var mutableCLP = self
        mutableCLP.readUserFields = fields
        return mutableCLP
    }
}

// MARK: WriteAccess
public extension ParseCLP {

    internal func setWrite(_ allowed: Bool, access: String) -> Self {
        var mutableCLP = self
        mutableCLP.get = [access: allowed]
        mutableCLP.update = [access: allowed]
        mutableCLP.delete = [access: allowed]
        mutableCLP.addField = [access: allowed]
        return mutableCLP
    }

    /**
     Sets whether the public is allowed to write this class.

     - parameter allowed: **true** if access should be allowed, **false** otherwise.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setPublicWriteAccess(_ allowed: Bool) -> Self {
        setWrite(allowed, access: Access.publicScope.rawValue)
    }

    /**
     Sets whether the given user objectId is allowed to write to this class.
     
     - parameter userObjectId: The user objectId to provide/restrict access to.
     - parameter allowed: **true** if access should be allowed, **false** otherwise.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setWriteAccess(_ allowed: Bool, userObjectId: String) -> Self {
        setWrite(allowed, access: userObjectId)
    }

    /**
     Sets whether the given `ParseUser` is allowed to write to this class.
     
     - parameter role: The `ParseUser` to provide/restrict access to.
     - parameter allowed: **true** if access should be allowed, **false** otherwise.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setWriteAccess<U>(_ allowed: Bool, user: U) throws -> Self where U: ParseUser {
        let userPointer = try user.toPointer()
        return setWrite(allowed, access: userPointer.objectId)
    }

    /**
     Sets whether the given `ParseRole` is allowed to write to this class.
     
     - parameter role: The `ParseRole` to provide/restrict access to.
     - parameter allowed: **true** if access should be allowed, **false** otherwise.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setWriteAccess<R>(_ allowed: Bool, role: R) throws -> Self where R: ParseRole {
        let roleAccess = try toRole(role: role)
        return setWrite(allowed, access: roleAccess)
    }
}

// MARK: ReadAccess
public extension ParseCLP {

    internal func setRead(_ allowed: Bool, access: String) -> Self {
        var mutableCLP = self
        mutableCLP.get = [access: allowed]
        mutableCLP.find = [access: allowed]
        mutableCLP.count = [access: allowed]
        return mutableCLP
    }

    /**
     Sets whether the public is allowed to read this class.

     - parameter allowed: **true** if access should be allowed, **false** otherwise.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setPublicReadAccess(_ allowed: Bool) -> Self {
        setRead(allowed, access: Access.publicScope.rawValue)
    }

    /**
     Sets whether the given user objectId is allowed to read this class.
     
     - parameter userObjectId: The user objectId to provide/restrict access to.
     - parameter allowed: **true** if access should be allowed, **false** otherwise.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setReadAccess(_ allowed: Bool, userObjectId: String) -> Self {
        setRead(allowed, access: userObjectId)
    }

    /**
     Sets whether the given `ParseUser` is allowed to read this class.
     
     - parameter role: The `ParseUser` to provide/restrict access to.
     - parameter allowed: **true** if access should be allowed, **false** otherwise.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setReadAccess<U>(_ allowed: Bool, user: U) throws -> Self where U: ParseUser {
        let userPointer = try user.toPointer()
        return setRead(allowed, access: userPointer.objectId)
    }

    /**
     Sets whether the given `ParseRole` is allowed to read this class.
     
     - parameter role: The `ParseRole` to provide/restrict access to.
     - parameter allowed: **true** if access should be allowed, **false** otherwise.
     - returns: A mutated instance of `ParseCLP` for easy chaining.
    */
    func setReadAccess<R>(_ allowed: Bool, role: R) throws -> Self where R: ParseRole {
        let roleAccess = try toRole(role: role)
        return setRead(allowed, access: roleAccess)
    }
}
