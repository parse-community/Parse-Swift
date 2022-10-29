//
//  ParseCLPTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 5/28/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class ParseCLPTests: XCTestCase { // swiftlint:disable:this type_body_length

    struct User: ParseUser {

        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        // These are required by ParseUser
        var username: String?
        var email: String?
        var emailVerified: Bool?
        var password: String?
        var authData: [String: [String: String]?]?

        // Your custom keys
        var customKey: String?

        init() { }
    }

    struct Role<RoleUser: ParseUser>: ParseRole {

        // required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        // provided by Role
        var name: String?
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        guard let url = URL(string: "http://localhost:1337/1") else {
            XCTFail("Should create valid URL")
            return
        }
        ParseSwift.initialize(applicationId: "applicationId",
                              clientKey: "clientKey",
                              primaryKey: "primaryKey",
                              serverURL: url,
                              testing: true)
    }

    let objectId = "1234"
    let user = User(objectId: "1234")

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        MockURLProtocol.removeAll()
        #if !os(Linux) && !os(Android) && !os(Windows)
        try KeychainStore.shared.deleteAll()
        #endif
        try ParseStorage.shared.deleteAll()
    }

    func testInitializerRequiresAuthentication() throws {
        let clp = ParseCLP(requiresAuthentication: true, publicAccess: false)
        XCTAssertEqual(clp.get?[ParseCLP.Access.requiresAuthentication.rawValue], true)
        XCTAssertEqual(clp.find?[ParseCLP.Access.requiresAuthentication.rawValue], true)
        XCTAssertEqual(clp.create?[ParseCLP.Access.requiresAuthentication.rawValue], true)
        XCTAssertEqual(clp.update?[ParseCLP.Access.requiresAuthentication.rawValue], true)
        XCTAssertEqual(clp.delete?[ParseCLP.Access.requiresAuthentication.rawValue], true)
        XCTAssertEqual(clp.count?[ParseCLP.Access.requiresAuthentication.rawValue], true)
        XCTAssertNil(clp.addField?[ParseCLP.Access.requiresAuthentication.rawValue])
        XCTAssertNil(clp.protectedFields)
        XCTAssertNil(clp.readUserFields)
        XCTAssertNil(clp.writeUserFields)
        XCTAssertNil(clp.get?[ParseCLP.Access.publicScope.rawValue])
        XCTAssertNil(clp.find?[ParseCLP.Access.publicScope.rawValue])
        XCTAssertNil(clp.create?[ParseCLP.Access.publicScope.rawValue])
        XCTAssertNil(clp.update?[ParseCLP.Access.publicScope.rawValue])
        XCTAssertNil(clp.delete?[ParseCLP.Access.publicScope.rawValue])
        XCTAssertNil(clp.count?[ParseCLP.Access.publicScope.rawValue])
        XCTAssertNil(clp.addField?[ParseCLP.Access.publicScope.rawValue])
    }

    func testInitializerPublicAccess() throws {
        let clp = ParseCLP(requiresAuthentication: false, publicAccess: true)
        XCTAssertEqual(clp.get?[ParseCLP.Access.publicScope.rawValue], true)
        XCTAssertEqual(clp.find?[ParseCLP.Access.publicScope.rawValue], true)
        XCTAssertEqual(clp.create?[ParseCLP.Access.publicScope.rawValue], true)
        XCTAssertEqual(clp.update?[ParseCLP.Access.publicScope.rawValue], true)
        XCTAssertEqual(clp.delete?[ParseCLP.Access.publicScope.rawValue], true)
        XCTAssertEqual(clp.count?[ParseCLP.Access.publicScope.rawValue], true)
        XCTAssertNil(clp.addField?[ParseCLP.Access.publicScope.rawValue])
        XCTAssertNil(clp.protectedFields)
        XCTAssertNil(clp.readUserFields)
        XCTAssertNil(clp.writeUserFields)
        XCTAssertNil(clp.get?[ParseCLP.Access.requiresAuthentication.rawValue])
        XCTAssertNil(clp.find?[ParseCLP.Access.requiresAuthentication.rawValue])
        XCTAssertNil(clp.create?[ParseCLP.Access.requiresAuthentication.rawValue])
        XCTAssertNil(clp.update?[ParseCLP.Access.requiresAuthentication.rawValue])
        XCTAssertNil(clp.delete?[ParseCLP.Access.requiresAuthentication.rawValue])
        XCTAssertNil(clp.count?[ParseCLP.Access.requiresAuthentication.rawValue])
        XCTAssertNil(clp.addField?[ParseCLP.Access.requiresAuthentication.rawValue])
    }

    func testInitializerRequireAndPublicAccess() throws {
        let clp = ParseCLP(requiresAuthentication: true, publicAccess: true)
        XCTAssertEqual(clp.get?[ParseCLP.Access.publicScope.rawValue], true)
        XCTAssertEqual(clp.find?[ParseCLP.Access.publicScope.rawValue], true)
        XCTAssertEqual(clp.create?[ParseCLP.Access.publicScope.rawValue], true)
        XCTAssertEqual(clp.update?[ParseCLP.Access.publicScope.rawValue], true)
        XCTAssertEqual(clp.delete?[ParseCLP.Access.publicScope.rawValue], true)
        XCTAssertEqual(clp.count?[ParseCLP.Access.publicScope.rawValue], true)
        XCTAssertNil(clp.addField?[ParseCLP.Access.publicScope.rawValue])
        XCTAssertNil(clp.protectedFields)
        XCTAssertNil(clp.readUserFields)
        XCTAssertNil(clp.writeUserFields)
        XCTAssertEqual(clp.get?[ParseCLP.Access.requiresAuthentication.rawValue], true)
        XCTAssertEqual(clp.find?[ParseCLP.Access.requiresAuthentication.rawValue], true)
        XCTAssertEqual(clp.create?[ParseCLP.Access.requiresAuthentication.rawValue], true)
        XCTAssertEqual(clp.update?[ParseCLP.Access.requiresAuthentication.rawValue], true)
        XCTAssertEqual(clp.delete?[ParseCLP.Access.requiresAuthentication.rawValue], true)
        XCTAssertEqual(clp.count?[ParseCLP.Access.requiresAuthentication.rawValue], true)
        XCTAssertNil(clp.addField?[ParseCLP.Access.requiresAuthentication.rawValue])
    }

    func testPointerFields() throws {
        let fields = Set<String>(["hello", "world"])
        let clp = ParseCLP().setPointerFields(fields, on: .create)
        XCTAssertEqual(clp.getPointerFields(.create), fields)

        let newField = Set<String>(["new"])
        let clp2 = clp.addPointerFields(newField, on: .create)
        XCTAssertEqual(clp2.getPointerFields(.create), fields.union(newField))

        let clp3 = clp2.removePointerFields(newField, on: .create)
        XCTAssertEqual(clp3.getPointerFields(.create), fields)

        let clp4 = ParseCLP().addPointerFields(newField, on: .create)
        XCTAssertEqual(clp4.getPointerFields(.create), newField)

        let clp5 = ParseCLP().setAccess(true, on: .create, for: "yo")
            .setPointerFields(fields, on: .create)
        XCTAssertEqual(clp5.getPointerFields(.create), fields)
        XCTAssertEqual(clp5.hasAccess(.create, for: "yo"), true)
    }

    func testPointerFieldsEncode() throws {
        let fields = Set<String>(["world"])
        let clp = ParseCLP().setPointerFields(fields, on: .create)
        XCTAssertEqual(clp.description, "{\"create\":{\"pointerFields\":[\"world\"]}}")
    }

    func testPointerAndWriteAccessPublicSetEncode() throws {
        let fields = Set<String>(["world"])
        let clp = ParseCLP()
            .setPointerFields(fields, on: .create)
            .setWriteAccessPublic(true, canAddField: true)
        // swiftlint:disable:next line_length
        XCTAssertEqual(clp.description, "{\"addField\":{\"*\":true},\"create\":{\"*\":true,\"pointerFields\":[\"world\"]},\"delete\":{\"*\":true},\"update\":{\"*\":true}}")
    }

    func testProtectedFieldsPublic() throws {
        let fields = Set<String>(["hello", "world"])
        let clp = ParseCLP().setProtectedFieldsPublic(fields)
        XCTAssertEqual(clp.getProtectedFieldsPublic(), fields)

        let newField = Set<String>(["new"])
        let clp2 = clp.addProtectedFieldsPublic(newField)
        XCTAssertEqual(clp2.getProtectedFieldsPublic(), fields.union(newField))

        let clp3 = clp2.removeProtectedFieldsPublic(newField)
        XCTAssertEqual(clp3.getProtectedFieldsPublic(), fields)

        let clp4 = ParseCLP().addProtectedFieldsPublic(newField)
        XCTAssertEqual(clp4.getProtectedFieldsPublic(), newField)

        let clp5 = clp.setProtectedFieldsRequiresAuthentication(newField)
        XCTAssertEqual(clp5.getProtectedFieldsPublic(), fields)
        XCTAssertEqual(clp5.getProtectedFieldsRequiresAuthentication(), newField)
    }

    func testProtectedFieldsRequiresAuthentication() throws {
        let fields = Set<String>(["hello", "world"])
        let clp = ParseCLP().setProtectedFieldsRequiresAuthentication(fields)
        XCTAssertEqual(clp.getProtectedFieldsRequiresAuthentication(), fields)

        let newField = Set<String>(["new"])
        let clp2 = clp.addProtectedFieldsRequiresAuthentication(newField)
        XCTAssertEqual(clp2.getProtectedFieldsRequiresAuthentication(), fields.union(newField))

        let clp3 = clp2.removeProtectedFieldsRequiresAuthentication(newField)
        XCTAssertEqual(clp3.getProtectedFieldsRequiresAuthentication(), fields)

        let clp4 = ParseCLP().addProtectedFieldsRequiresAuthentication(newField)
        XCTAssertEqual(clp4.getProtectedFieldsRequiresAuthentication(), newField)
    }

    func testProtectedFieldsUserField() throws {
        let fields = Set<String>(["hello", "world"])
        let userField = "peace"
        let clp = ParseCLP().setProtectedFields(fields, userField: userField)
        XCTAssertEqual(clp.getProtectedFieldsUser(userField), fields)

        let newField = Set<String>(["new"])
        let clp2 = clp.addProtectedFieldsUser(newField, userField: userField)
        XCTAssertEqual(clp2.getProtectedFieldsUser(userField), fields.union(newField))

        let clp3 = clp2.removeProtectedFieldsUser(newField, userField: userField)
        XCTAssertEqual(clp3.getProtectedFieldsUser(userField), fields)

        let clp4 = ParseCLP().addProtectedFieldsUser(newField, userField: userField)
        XCTAssertEqual(clp4.getProtectedFieldsUser(userField), newField)
    }

    func testProtectedFieldsObjectId() throws {
        let fields = Set<String>(["hello", "world"])
        let clp = ParseCLP().setProtectedFields(fields, for: objectId)
        XCTAssertEqual(clp.getProtectedFields(objectId), fields)

        let newField = Set<String>(["new"])
        let clp2 = clp.addProtectedFields(newField, for: objectId)
        XCTAssertEqual(clp2.getProtectedFields(objectId), fields.union(newField))

        let clp3 = clp2.removeProtectedFields(newField, for: objectId)
        XCTAssertEqual(clp3.getProtectedFields(objectId), fields)

        let clp4 = ParseCLP().addProtectedFields(newField, for: objectId)
        XCTAssertEqual(clp4.getProtectedFields(objectId), newField)
    }

    func testProtectedFieldsUser() throws {
        let fields = Set<String>(["hello", "world"])
        let clp = try ParseCLP().setProtectedFields(fields, for: user)
        XCTAssertEqual(try clp.getProtectedFields(user), fields)

        let newField = Set<String>(["new"])
        let clp2 = try clp.addProtectedFields(newField, for: user)
        XCTAssertEqual(try clp2.getProtectedFields(user), fields.union(newField))

        let clp3 = try clp2.removeProtectedFields(newField, for: user)
        XCTAssertEqual(try clp3.getProtectedFields(user), fields)

        let clp4 = try ParseCLP().addProtectedFields(newField, for: user)
        XCTAssertEqual(try clp4.getProtectedFields(user), newField)
    }

    func testProtectedFieldsPointer() throws {
        let pointer = try user.toPointer()
        let fields = Set<String>(["hello", "world"])
        let clp = ParseCLP().setProtectedFields(fields, for: pointer)
        XCTAssertEqual(clp.getProtectedFields(pointer), fields)

        let newField = Set<String>(["new"])
        let clp2 = clp.addProtectedFields(newField, for: pointer)
        XCTAssertEqual(clp2.getProtectedFields(pointer), fields.union(newField))

        let clp3 = clp2.removeProtectedFields(newField, for: pointer)
        XCTAssertEqual(clp3.getProtectedFields(pointer), fields)

        let clp4 = ParseCLP().addProtectedFields(newField, for: pointer)
        XCTAssertEqual(clp4.getProtectedFields(pointer), newField)
    }

    func testProtectedFieldsRole() throws {
        let role = try Role<User>(name: "hello")
        let fields = Set<String>(["hello", "world"])
        let clp = try ParseCLP().setProtectedFields(fields, for: role)
        XCTAssertEqual(try clp.getProtectedFields(role), fields)

        let newField = Set<String>(["new"])
        let clp2 = try clp.addProtectedFields(newField, for: role)
        XCTAssertEqual(try clp2.getProtectedFields(role), fields.union(newField))

        let clp3 = try clp2.removeProtectedFields(newField, for: role)
        XCTAssertEqual(try clp3.getProtectedFields(role), fields)

        let clp4 = try ParseCLP().addProtectedFields(newField, for: role)
        XCTAssertEqual(try clp4.getProtectedFields(role), newField)
    }

    func testProtectedFieldsEncode() throws {
        let role = try Role<User>(name: "hello")
        let fields = Set<String>(["world"])
        let clp = try ParseCLP().setProtectedFields(fields, for: role)
        XCTAssertEqual(clp.description, "{\"protectedFields\":{\"role:hello\":[\"world\"]}}")
    }

    func testPublicAccess() throws {
        let clp = ParseCLP().setAccessPublic(true, on: .create)
        XCTAssertTrue(clp.hasAccessPublic(.create))

        let clp2 = clp.setAccessPublic(false, on: .create)
        XCTAssertFalse(clp2.hasAccessPublic(.create))
    }

    func testRequiresAuthenticationAccess() throws {
        let clp = ParseCLP().setAccessRequiresAuthentication(true, on: .create)
        XCTAssertTrue(clp.hasAccessRequiresAuthentication(.create))

        let clp2 = clp.setAccessRequiresAuthentication(false, on: .create)
        XCTAssertFalse(clp2.hasAccessRequiresAuthentication(.create))
    }

    func testAccessUser() throws {
        let clp = try ParseCLP().setAccess(true, on: .create, for: user)
        XCTAssertTrue(try clp.hasAccess(.create, for: user))

        let clp2 = try clp.setAccess(false, on: .create, for: user)
        XCTAssertFalse(try clp2.hasAccess(.create, for: user))
    }

    func testAccessPointer() throws {
        let user = try user.toPointer()
        let clp = ParseCLP().setAccess(true, on: .create, for: user)
        XCTAssertTrue(clp.hasAccess(.create, for: user))

        let clp2 = clp.setAccess(false, on: .create, for: user)
        XCTAssertFalse(clp2.hasAccess(.create, for: user))
    }

    func testAccessRole() throws {
        let role = try Role<User>(name: "hello")
        let clp = try ParseCLP().setAccess(true, on: .create, for: role)
        XCTAssertTrue(try clp.hasAccess(.create, for: role))

        let clp2 = try clp.setAccess(false, on: .create, for: role)
        XCTAssertFalse(try clp2.hasAccess(.create, for: user))
    }

    func testAccessEncode() throws {
        let clp = ParseCLP().setAccess(true, on: .create, for: objectId)
        XCTAssertEqual(clp.description, "{\"create\":{\"\(objectId)\":true}}")
    }

    func testWriteAccessPublicSet() throws {
        let clp = ParseCLP().setWriteAccessPublic(true)
        XCTAssertNil(clp.get?[ParseCLP.Access.publicScope.rawValue])
        XCTAssertNil(clp.find?[ParseCLP.Access.publicScope.rawValue])
        XCTAssertEqual(clp.create?[ParseCLP.Access.publicScope.rawValue], true)
        XCTAssertEqual(clp.update?[ParseCLP.Access.publicScope.rawValue], true)
        XCTAssertEqual(clp.delete?[ParseCLP.Access.publicScope.rawValue], true)
        XCTAssertNil(clp.count?[ParseCLP.Access.publicScope.rawValue])
        XCTAssertNil(clp.addField?[ParseCLP.Access.publicScope.rawValue])

        let clp2 = ParseCLP().setWriteAccessPublic(true, canAddField: true)
        XCTAssertNil(clp2.get?[ParseCLP.Access.publicScope.rawValue])
        XCTAssertNil(clp2.find?[ParseCLP.Access.publicScope.rawValue])
        XCTAssertEqual(clp2.create?[ParseCLP.Access.publicScope.rawValue], true)
        XCTAssertEqual(clp2.update?[ParseCLP.Access.publicScope.rawValue], true)
        XCTAssertEqual(clp2.delete?[ParseCLP.Access.publicScope.rawValue], true)
        XCTAssertNil(clp2.count?[ParseCLP.Access.publicScope.rawValue])
        XCTAssertEqual(clp2.addField?[ParseCLP.Access.publicScope.rawValue], true)

        let clp3 = clp.setWriteAccessPublic(false)
        XCTAssertNil(clp3.get?[ParseCLP.Access.publicScope.rawValue])
        XCTAssertNil(clp3.find?[ParseCLP.Access.publicScope.rawValue])
        XCTAssertNil(clp3.create?[ParseCLP.Access.publicScope.rawValue])
        XCTAssertNil(clp3.update?[ParseCLP.Access.publicScope.rawValue])
        XCTAssertNil(clp3.delete?[ParseCLP.Access.publicScope.rawValue])
        XCTAssertNil(clp3.count?[ParseCLP.Access.publicScope.rawValue])
        XCTAssertNil(clp3.addField?[ParseCLP.Access.publicScope.rawValue])

        let clp4 = clp2.setWriteAccessPublic(false)
        XCTAssertNil(clp4.get?[ParseCLP.Access.publicScope.rawValue])
        XCTAssertNil(clp4.find?[ParseCLP.Access.publicScope.rawValue])
        XCTAssertNil(clp4.create?[ParseCLP.Access.publicScope.rawValue])
        XCTAssertNil(clp4.update?[ParseCLP.Access.publicScope.rawValue])
        XCTAssertNil(clp4.delete?[ParseCLP.Access.publicScope.rawValue])
        XCTAssertNil(clp4.count?[ParseCLP.Access.publicScope.rawValue])
        XCTAssertNil(clp4.addField?[ParseCLP.Access.publicScope.rawValue])
    }

    func testWriteAccessPublicSetEncode() throws {
        let clp = ParseCLP().setWriteAccessPublic(true, canAddField: true)
        // swiftlint:disable:next line_length
        XCTAssertEqual(clp.description, "{\"addField\":{\"*\":true},\"create\":{\"*\":true},\"delete\":{\"*\":true},\"update\":{\"*\":true}}")
    }

    func testWriteAccessRequiresAuthenticationSet() throws {
        let clp = ParseCLP().setWriteAccessRequiresAuthentication(true)
        XCTAssertNil(clp.get?[ParseCLP.Access.requiresAuthentication.rawValue])
        XCTAssertNil(clp.find?[ParseCLP.Access.requiresAuthentication.rawValue])
        XCTAssertEqual(clp.create?[ParseCLP.Access.requiresAuthentication.rawValue], true)
        XCTAssertEqual(clp.update?[ParseCLP.Access.requiresAuthentication.rawValue], true)
        XCTAssertEqual(clp.delete?[ParseCLP.Access.requiresAuthentication.rawValue], true)
        XCTAssertNil(clp.count?[ParseCLP.Access.requiresAuthentication.rawValue])
        XCTAssertNil(clp.addField?[ParseCLP.Access.requiresAuthentication.rawValue])

        let clp2 = ParseCLP().setWriteAccessRequiresAuthentication(true, canAddField: true)
        XCTAssertNil(clp2.get?[ParseCLP.Access.requiresAuthentication.rawValue])
        XCTAssertNil(clp2.find?[ParseCLP.Access.requiresAuthentication.rawValue])
        XCTAssertEqual(clp2.create?[ParseCLP.Access.requiresAuthentication.rawValue], true)
        XCTAssertEqual(clp2.update?[ParseCLP.Access.requiresAuthentication.rawValue], true)
        XCTAssertEqual(clp2.delete?[ParseCLP.Access.requiresAuthentication.rawValue], true)
        XCTAssertNil(clp2.count?[ParseCLP.Access.requiresAuthentication.rawValue])
        XCTAssertEqual(clp2.addField?[ParseCLP.Access.requiresAuthentication.rawValue], true)

        let clp3 = clp.setWriteAccessRequiresAuthentication(false)
        XCTAssertNil(clp3.get?[ParseCLP.Access.requiresAuthentication.rawValue])
        XCTAssertNil(clp3.find?[ParseCLP.Access.requiresAuthentication.rawValue])
        XCTAssertNil(clp3.create?[ParseCLP.Access.requiresAuthentication.rawValue])
        XCTAssertNil(clp3.update?[ParseCLP.Access.requiresAuthentication.rawValue])
        XCTAssertNil(clp3.delete?[ParseCLP.Access.requiresAuthentication.rawValue])
        XCTAssertNil(clp3.count?[ParseCLP.Access.requiresAuthentication.rawValue])
        XCTAssertNil(clp3.addField?[ParseCLP.Access.requiresAuthentication.rawValue])

        let clp4 = clp2.setWriteAccessRequiresAuthentication(false)
        XCTAssertNil(clp4.get?[ParseCLP.Access.requiresAuthentication.rawValue])
        XCTAssertNil(clp4.find?[ParseCLP.Access.requiresAuthentication.rawValue])
        XCTAssertNil(clp4.create?[ParseCLP.Access.requiresAuthentication.rawValue])
        XCTAssertNil(clp4.update?[ParseCLP.Access.requiresAuthentication.rawValue])
        XCTAssertNil(clp4.delete?[ParseCLP.Access.requiresAuthentication.rawValue])
        XCTAssertNil(clp4.count?[ParseCLP.Access.requiresAuthentication.rawValue])
        XCTAssertNil(clp4.addField?[ParseCLP.Access.requiresAuthentication.rawValue])
    }

    func testWriteAccessRequiresAuthenticationSetEncode() throws {
        let clp = ParseCLP().setWriteAccessRequiresAuthentication(true, canAddField: true)
        // swiftlint:disable:next line_length
        XCTAssertEqual(clp.description, "{\"addField\":{\"requiresAuthentication\":true},\"create\":{\"requiresAuthentication\":true},\"delete\":{\"requiresAuthentication\":true},\"update\":{\"requiresAuthentication\":true}}")
    }

    func testWriteAccessObjectIdSet() throws {
        let clp = ParseCLP().setWriteAccess(true, for: objectId)
        XCTAssertNil(clp.get?[objectId])
        XCTAssertNil(clp.find?[objectId])
        XCTAssertEqual(clp.create?[objectId], true)
        XCTAssertEqual(clp.update?[objectId], true)
        XCTAssertEqual(clp.delete?[objectId], true)
        XCTAssertNil(clp.count?[objectId])
        XCTAssertNil(clp.addField?[objectId])

        let clp2 = ParseCLP().setWriteAccess(true, for: objectId, canAddField: true)
        XCTAssertNil(clp2.get?[objectId])
        XCTAssertNil(clp2.find?[objectId])
        XCTAssertEqual(clp2.create?[objectId], true)
        XCTAssertEqual(clp2.update?[objectId], true)
        XCTAssertEqual(clp2.delete?[objectId], true)
        XCTAssertNil(clp2.count?[objectId])
        XCTAssertEqual(clp2.addField?[objectId], true)

        let clp3 = clp.setWriteAccess(false, for: objectId)
        XCTAssertNil(clp3.get?[objectId])
        XCTAssertNil(clp3.find?[objectId])
        XCTAssertNil(clp3.create?[objectId])
        XCTAssertNil(clp3.update?[objectId])
        XCTAssertNil(clp3.delete?[objectId])
        XCTAssertNil(clp3.count?[objectId])
        XCTAssertNil(clp3.addField?[objectId])

        let clp4 = clp2.setWriteAccess(false, for: objectId)
        XCTAssertNil(clp4.get?[objectId])
        XCTAssertNil(clp4.find?[objectId])
        XCTAssertNil(clp4.create?[objectId])
        XCTAssertNil(clp4.update?[objectId])
        XCTAssertNil(clp4.delete?[objectId])
        XCTAssertNil(clp4.count?[objectId])
        XCTAssertNil(clp4.addField?[objectId])
    }

    func testWriteAccessObjectIdSetEncode() throws {
        let clp = ParseCLP().setWriteAccess(true, for: objectId, canAddField: true)
        // swiftlint:disable:next line_length
        XCTAssertEqual(clp.description, "{\"addField\":{\"\(objectId)\":true},\"create\":{\"\(objectId)\":true},\"delete\":{\"\(objectId)\":true},\"update\":{\"\(objectId)\":true}}")
    }

    func testWriteAccessUserSet() throws {
        let clp = try ParseCLP().setWriteAccess(true, for: user)
        XCTAssertNil(clp.get?[objectId])
        XCTAssertNil(clp.find?[objectId])
        XCTAssertEqual(clp.create?[objectId], true)
        XCTAssertEqual(clp.update?[objectId], true)
        XCTAssertEqual(clp.delete?[objectId], true)
        XCTAssertNil(clp.count?[objectId])
        XCTAssertNil(clp.addField?[objectId])

        let clp2 = try ParseCLP().setWriteAccess(true, for: user, canAddField: true)
        XCTAssertNil(clp2.get?[objectId])
        XCTAssertNil(clp2.find?[objectId])
        XCTAssertEqual(clp2.create?[objectId], true)
        XCTAssertEqual(clp2.update?[objectId], true)
        XCTAssertEqual(clp2.delete?[objectId], true)
        XCTAssertNil(clp2.count?[objectId])
        XCTAssertEqual(clp2.addField?[objectId], true)

        let clp3 = try clp.setWriteAccess(false, for: user)
        XCTAssertNil(clp3.get?[objectId])
        XCTAssertNil(clp3.find?[objectId])
        XCTAssertNil(clp3.create?[objectId])
        XCTAssertNil(clp3.update?[objectId])
        XCTAssertNil(clp3.delete?[objectId])
        XCTAssertNil(clp3.count?[objectId])
        XCTAssertNil(clp3.addField?[objectId])

        let clp4 = try clp2.setWriteAccess(false, for: user)
        XCTAssertNil(clp4.get?[objectId])
        XCTAssertNil(clp4.find?[objectId])
        XCTAssertNil(clp4.create?[objectId])
        XCTAssertNil(clp4.update?[objectId])
        XCTAssertNil(clp4.delete?[objectId])
        XCTAssertNil(clp4.count?[objectId])
        XCTAssertNil(clp4.addField?[objectId])
    }

    func testWriteAccessUserSetEncode() throws {
        let clp = try ParseCLP().setWriteAccess(true, for: user, canAddField: true)
        // swiftlint:disable:next line_length
        XCTAssertEqual(clp.description, "{\"addField\":{\"\(objectId)\":true},\"create\":{\"\(objectId)\":true},\"delete\":{\"\(objectId)\":true},\"update\":{\"\(objectId)\":true}}")
    }

    func testWriteAccessPointerSet() throws {
        let clp = ParseCLP().setWriteAccess(true, for: try user.toPointer())
        XCTAssertNil(clp.get?[objectId])
        XCTAssertNil(clp.find?[objectId])
        XCTAssertEqual(clp.create?[objectId], true)
        XCTAssertEqual(clp.update?[objectId], true)
        XCTAssertEqual(clp.delete?[objectId], true)
        XCTAssertNil(clp.count?[objectId])
        XCTAssertNil(clp.addField?[objectId])

        let clp2 = ParseCLP().setWriteAccess(true,
                                             for: try user.toPointer(),
                                             canAddField: true)
        XCTAssertNil(clp2.get?[objectId])
        XCTAssertNil(clp2.find?[objectId])
        XCTAssertEqual(clp2.create?[objectId], true)
        XCTAssertEqual(clp2.update?[objectId], true)
        XCTAssertEqual(clp2.delete?[objectId], true)
        XCTAssertNil(clp2.count?[objectId])
        XCTAssertEqual(clp2.addField?[objectId], true)

        let clp3 = clp.setWriteAccess(false, for: try user.toPointer())
        XCTAssertNil(clp3.get?[objectId])
        XCTAssertNil(clp3.find?[objectId])
        XCTAssertNil(clp3.create?[objectId])
        XCTAssertNil(clp3.update?[objectId])
        XCTAssertNil(clp3.delete?[objectId])
        XCTAssertNil(clp3.count?[objectId])
        XCTAssertNil(clp3.addField?[objectId])

        let clp4 = clp2.setWriteAccess(false, for: try user.toPointer())
        XCTAssertNil(clp4.get?[objectId])
        XCTAssertNil(clp4.find?[objectId])
        XCTAssertNil(clp4.create?[objectId])
        XCTAssertNil(clp4.update?[objectId])
        XCTAssertNil(clp4.delete?[objectId])
        XCTAssertNil(clp4.count?[objectId])
        XCTAssertNil(clp4.addField?[objectId])
    }

    func testWriteAccessPointerSetEncode() throws {
        let clp = ParseCLP().setWriteAccess(true,
                                            for: try user.toPointer(),
                                            canAddField: true)
        // swiftlint:disable:next line_length
        XCTAssertEqual(clp.description, "{\"addField\":{\"\(objectId)\":true},\"create\":{\"\(objectId)\":true},\"delete\":{\"\(objectId)\":true},\"update\":{\"\(objectId)\":true}}")
    }

    func testWriteAccessRoleSet() throws {
        let name = "hello"
        let role = try Role<User>(name: name)
        let roleName = try ParseACL.getRoleAccessName(role)
        let clp = try ParseCLP().setWriteAccess(true, for: role)
        XCTAssertNil(clp.get?[roleName])
        XCTAssertNil(clp.find?[roleName])
        XCTAssertEqual(clp.create?[roleName], true)
        XCTAssertEqual(clp.update?[roleName], true)
        XCTAssertEqual(clp.delete?[roleName], true)
        XCTAssertNil(clp.count?[roleName])
        XCTAssertNil(clp.addField?[roleName])

        let clp2 = try ParseCLP().setWriteAccess(true,
                                                 for: role,
                                                 canAddField: true)
        XCTAssertNil(clp2.get?[roleName])
        XCTAssertNil(clp2.find?[roleName])
        XCTAssertEqual(clp2.create?[roleName], true)
        XCTAssertEqual(clp2.update?[roleName], true)
        XCTAssertEqual(clp2.delete?[roleName], true)
        XCTAssertNil(clp2.count?[roleName])
        XCTAssertEqual(clp2.addField?[roleName], true)

        let clp3 = try clp.setWriteAccess(false, for: role)
        XCTAssertNil(clp3.get?[roleName])
        XCTAssertNil(clp3.find?[roleName])
        XCTAssertNil(clp3.create?[roleName])
        XCTAssertNil(clp3.update?[roleName])
        XCTAssertNil(clp3.delete?[roleName])
        XCTAssertNil(clp3.count?[roleName])
        XCTAssertNil(clp3.addField?[roleName])

        let clp4 = try clp2.setWriteAccess(false, for: role)
        XCTAssertNil(clp4.get?[roleName])
        XCTAssertNil(clp4.find?[roleName])
        XCTAssertNil(clp4.create?[roleName])
        XCTAssertNil(clp4.update?[roleName])
        XCTAssertNil(clp4.delete?[roleName])
        XCTAssertNil(clp4.count?[roleName])
        XCTAssertNil(clp4.addField?[roleName])
    }

    func testWriteAccessRoleSetEncode() throws {
        let name = "hello"
        let role = try Role<User>(name: name)
        let roleName = try ParseACL.getRoleAccessName(role)
        let clp = try ParseCLP().setWriteAccess(true,
                                                for: role,
                                                canAddField: true)
        // swiftlint:disable:next line_length
        XCTAssertEqual(clp.description, "{\"addField\":{\"\(roleName)\":true},\"create\":{\"\(roleName)\":true},\"delete\":{\"\(roleName)\":true},\"update\":{\"\(roleName)\":true}}")
    }

    func testWriteAccessPublicHas() throws {
        let clp = ParseCLP().setWriteAccessPublic(true)
        XCTAssertTrue(clp.hasWriteAccessPublic())
        XCTAssertFalse(clp.hasWriteAccessRequiresAuthentication())

        let clp2 = ParseCLP().setWriteAccessPublic(false)
        XCTAssertFalse(clp2.hasWriteAccessPublic())
        XCTAssertFalse(clp2.hasWriteAccessRequiresAuthentication())

        let clp3 = clp.setWriteAccessPublic(false)
        XCTAssertFalse(clp3.hasWriteAccessPublic())
        XCTAssertFalse(clp3.hasWriteAccessRequiresAuthentication())
    }

    func testWriteAccessRequiresAuthenticationHas() throws {
        let clp = ParseCLP().setWriteAccessRequiresAuthentication(true)
        XCTAssertTrue(clp.hasWriteAccessRequiresAuthentication())
        XCTAssertFalse(clp.hasWriteAccessPublic())

        let clp2 = ParseCLP().setWriteAccessRequiresAuthentication(false)
        XCTAssertFalse(clp2.hasWriteAccessRequiresAuthentication())
        XCTAssertFalse(clp2.hasWriteAccessPublic())

        let clp3 = clp.setWriteAccessRequiresAuthentication(false)
        XCTAssertFalse(clp3.hasWriteAccessRequiresAuthentication())
        XCTAssertFalse(clp3.hasWriteAccessPublic())
    }

    func testWriteAccessObjectIdHas() throws {
        let clp = ParseCLP().setWriteAccess(true, for: objectId)
        XCTAssertFalse(clp.hasReadAccess(objectId))
        XCTAssertTrue(clp.hasWriteAccess(objectId))
        XCTAssertFalse(clp.hasWriteAccess(objectId, check: true))

        let clp2 = ParseCLP().setWriteAccess(false, for: objectId)
        XCTAssertFalse(clp2.hasReadAccess(objectId))
        XCTAssertFalse(clp2.hasWriteAccess(objectId))

        let clp3 = clp.setWriteAccess(false, for: objectId)
        XCTAssertFalse(clp3.hasReadAccess(objectId))
        XCTAssertFalse(clp3.hasWriteAccess(objectId))

        let clp4 = ParseCLP().setWriteAccess(true, for: objectId, canAddField: true)
        XCTAssertFalse(clp4.hasReadAccess(objectId))
        XCTAssertTrue(clp4.hasWriteAccess(objectId, check: true))
    }

    func testWriteAccessUserHas() throws {
        let clp = try ParseCLP().setWriteAccess(true, for: user)
        XCTAssertFalse(try clp.hasReadAccess(user))
        XCTAssertTrue(try clp.hasWriteAccess(user))
        XCTAssertFalse(try clp.hasWriteAccess(user, checkAddField: true))

        let clp2 = try ParseCLP().setWriteAccess(false, for: user)
        XCTAssertFalse(try clp2.hasReadAccess(user))
        XCTAssertFalse(try clp2.hasWriteAccess(user))

        let clp3 = try clp.setWriteAccess(false, for: user)
        XCTAssertFalse(try clp3.hasReadAccess(user))
        XCTAssertFalse(try clp3.hasWriteAccess(user))

        let clp4 = try ParseCLP().setWriteAccess(true, for: user, canAddField: true)
        XCTAssertFalse(try clp4.hasReadAccess(user))
        XCTAssertTrue(try clp4.hasWriteAccess(user, checkAddField: true))
    }

    func testWriteAccessPointerHas() throws {
        let clp = ParseCLP().setWriteAccess(true, for: try user.toPointer())
        XCTAssertFalse(clp.hasReadAccess(try user.toPointer()))
        XCTAssertTrue(clp.hasWriteAccess(try user.toPointer()))
        XCTAssertFalse(clp.hasWriteAccess(try user.toPointer(), checkAddField: true))

        let clp2 = ParseCLP().setWriteAccess(false, for: try user.toPointer())
        XCTAssertFalse(clp2.hasReadAccess(try user.toPointer()))
        XCTAssertFalse(clp2.hasWriteAccess(try user.toPointer()))

        let clp3 = clp.setWriteAccess(false, for: try user.toPointer())
        XCTAssertFalse(clp3.hasReadAccess(try user.toPointer()))
        XCTAssertFalse(clp3.hasWriteAccess(try user.toPointer()))

        let clp4 = ParseCLP().setWriteAccess(true, for: try user.toPointer(), canAddField: true)
        XCTAssertFalse(clp4.hasReadAccess(try user.toPointer()))
        XCTAssertTrue(clp4.hasWriteAccess(try user.toPointer(), checkAddField: true))
    }

    func testWriteAccessRoleHas() throws {
        let name = "hello"
        let role = try Role<User>(name: name)
        let clp = try ParseCLP().setWriteAccess(true, for: role)
        XCTAssertFalse(try clp.hasReadAccess(role))
        XCTAssertTrue(try clp.hasWriteAccess(role))
        XCTAssertFalse(try clp.hasWriteAccess(role, checkAddField: true))

        let clp2 = try ParseCLP().setWriteAccess(false, for: role)
        XCTAssertFalse(try clp2.hasReadAccess(role))
        XCTAssertFalse(try clp2.hasWriteAccess(role))

        let clp3 = try clp.setWriteAccess(false, for: role)
        XCTAssertFalse(try clp3.hasReadAccess(role))
        XCTAssertFalse(try clp3.hasWriteAccess(role))

        let clp4 = try ParseCLP().setWriteAccess(true, for: role, canAddField: true)
        XCTAssertFalse(try clp4.hasReadAccess(role))
        XCTAssertTrue(try clp4.hasWriteAccess(role, checkAddField: true))
    }

    func testReadAccessPublicSet() throws {
        let clp = ParseCLP().setReadAccessPublic(true)
        XCTAssertEqual(clp.get?[ParseCLP.Access.publicScope.rawValue], true)
        XCTAssertEqual(clp.find?[ParseCLP.Access.publicScope.rawValue], true)
        XCTAssertNil(clp.create?[ParseCLP.Access.publicScope.rawValue])
        XCTAssertNil(clp.update?[ParseCLP.Access.publicScope.rawValue])
        XCTAssertNil(clp.delete?[ParseCLP.Access.publicScope.rawValue])
        XCTAssertEqual(clp.count?[ParseCLP.Access.publicScope.rawValue], true)
        XCTAssertNil(clp.addField?[ParseCLP.Access.publicScope.rawValue])

        let clp2 = ParseCLP().setReadAccessPublic(false)
        XCTAssertNil(clp2.get?[ParseCLP.Access.publicScope.rawValue])
        XCTAssertNil(clp2.find?[ParseCLP.Access.publicScope.rawValue])
        XCTAssertNil(clp2.create?[ParseCLP.Access.publicScope.rawValue])
        XCTAssertNil(clp2.update?[ParseCLP.Access.publicScope.rawValue])
        XCTAssertNil(clp2.delete?[ParseCLP.Access.publicScope.rawValue])
        XCTAssertNil(clp2.count?[ParseCLP.Access.publicScope.rawValue])
        XCTAssertNil(clp2.addField?[ParseCLP.Access.publicScope.rawValue])

        let clp3 = clp.setReadAccessPublic(false)
        XCTAssertNil(clp3.get?[ParseCLP.Access.publicScope.rawValue])
        XCTAssertNil(clp3.find?[ParseCLP.Access.publicScope.rawValue])
        XCTAssertNil(clp3.create?[ParseCLP.Access.publicScope.rawValue])
        XCTAssertNil(clp3.update?[ParseCLP.Access.publicScope.rawValue])
        XCTAssertNil(clp3.delete?[ParseCLP.Access.publicScope.rawValue])
        XCTAssertNil(clp3.count?[ParseCLP.Access.publicScope.rawValue])
        XCTAssertNil(clp3.addField?[ParseCLP.Access.publicScope.rawValue])
    }

    func testReadAccessPublicSetEncode() throws {
        let clp = ParseCLP().setReadAccessPublic(true)
        XCTAssertEqual(clp.description,
                       "{\"count\":{\"*\":true},\"find\":{\"*\":true},\"get\":{\"*\":true}}")
    }

    func testReadAccessRequiresAuthenticationSet() throws {
        let clp = ParseCLP().setReadAccessRequiresAuthentication(true)
        XCTAssertEqual(clp.get?[ParseCLP.Access.requiresAuthentication.rawValue], true)
        XCTAssertEqual(clp.find?[ParseCLP.Access.requiresAuthentication.rawValue], true)
        XCTAssertNil(clp.create?[ParseCLP.Access.requiresAuthentication.rawValue])
        XCTAssertNil(clp.update?[ParseCLP.Access.requiresAuthentication.rawValue])
        XCTAssertNil(clp.delete?[ParseCLP.Access.requiresAuthentication.rawValue])
        XCTAssertEqual(clp.count?[ParseCLP.Access.requiresAuthentication.rawValue], true)
        XCTAssertNil(clp.addField?[ParseCLP.Access.requiresAuthentication.rawValue])

        let clp2 = ParseCLP().setReadAccessRequiresAuthentication(false)
        XCTAssertNil(clp2.get?[ParseCLP.Access.requiresAuthentication.rawValue])
        XCTAssertNil(clp2.find?[ParseCLP.Access.requiresAuthentication.rawValue])
        XCTAssertNil(clp2.create?[ParseCLP.Access.requiresAuthentication.rawValue])
        XCTAssertNil(clp2.update?[ParseCLP.Access.requiresAuthentication.rawValue])
        XCTAssertNil(clp2.delete?[ParseCLP.Access.requiresAuthentication.rawValue])
        XCTAssertNil(clp2.count?[ParseCLP.Access.requiresAuthentication.rawValue])
        XCTAssertNil(clp2.addField?[ParseCLP.Access.requiresAuthentication.rawValue])

        let clp3 = clp.setReadAccessRequiresAuthentication(false)
        XCTAssertNil(clp3.get?[ParseCLP.Access.requiresAuthentication.rawValue])
        XCTAssertNil(clp3.find?[ParseCLP.Access.requiresAuthentication.rawValue])
        XCTAssertNil(clp3.create?[ParseCLP.Access.requiresAuthentication.rawValue])
        XCTAssertNil(clp3.update?[ParseCLP.Access.requiresAuthentication.rawValue])
        XCTAssertNil(clp3.delete?[ParseCLP.Access.requiresAuthentication.rawValue])
        XCTAssertNil(clp3.count?[ParseCLP.Access.requiresAuthentication.rawValue])
        XCTAssertNil(clp3.addField?[ParseCLP.Access.requiresAuthentication.rawValue])
    }

    func testReadAccessRequiresAuthenticationSetEncode() throws {
        let clp = ParseCLP().setReadAccessRequiresAuthentication(true)
        // swiftlint:disable:next line_length
        XCTAssertEqual(clp.description, "{\"count\":{\"requiresAuthentication\":true},\"find\":{\"requiresAuthentication\":true},\"get\":{\"requiresAuthentication\":true}}")
    }

    func testReadAccessObjectIdSet() throws {
        let clp = ParseCLP().setReadAccess(true, for: objectId)
        XCTAssertEqual(clp.get?[objectId], true)
        XCTAssertEqual(clp.find?[objectId], true)
        XCTAssertNil(clp.create?[objectId])
        XCTAssertNil(clp.update?[objectId])
        XCTAssertNil(clp.delete?[objectId])
        XCTAssertEqual(clp.count?[objectId], true)
        XCTAssertNil(clp.addField?[objectId])

        let clp2 = ParseCLP().setReadAccess(false, for: objectId)
        XCTAssertNil(clp2.get?[objectId])
        XCTAssertNil(clp2.find?[objectId])
        XCTAssertNil(clp2.create?[objectId])
        XCTAssertNil(clp2.update?[objectId])
        XCTAssertNil(clp2.delete?[objectId])
        XCTAssertNil(clp2.count?[objectId])
        XCTAssertNil(clp2.addField?[objectId])

        let clp3 = clp.setReadAccess(false, for: objectId)
        XCTAssertNil(clp3.get?[objectId])
        XCTAssertNil(clp3.find?[objectId])
        XCTAssertNil(clp3.create?[objectId])
        XCTAssertNil(clp3.update?[objectId])
        XCTAssertNil(clp3.delete?[objectId])
        XCTAssertNil(clp3.count?[objectId])
        XCTAssertNil(clp3.addField?[objectId])
    }

    func testReadAccessObjectIdSetEncode() throws {
        let clp = ParseCLP().setReadAccess(true, for: objectId)
        // swiftlint:disable:next line_length
        XCTAssertEqual(clp.description, "{\"count\":{\"\(objectId)\":true},\"find\":{\"\(objectId)\":true},\"get\":{\"\(objectId)\":true}}")
    }

    func testReadAccessUserSet() throws {
        let clp = try ParseCLP().setReadAccess(true, for: user)
        XCTAssertEqual(clp.get?[objectId], true)
        XCTAssertEqual(clp.find?[objectId], true)
        XCTAssertNil(clp.create?[objectId])
        XCTAssertNil(clp.update?[objectId])
        XCTAssertNil(clp.delete?[objectId])
        XCTAssertEqual(clp.count?[objectId], true)
        XCTAssertNil(clp.addField?[objectId])

        let clp2 = try ParseCLP().setReadAccess(false, for: user)
        XCTAssertNil(clp2.get?[objectId])
        XCTAssertNil(clp2.find?[objectId])
        XCTAssertNil(clp2.create?[objectId])
        XCTAssertNil(clp2.update?[objectId])
        XCTAssertNil(clp2.delete?[objectId])
        XCTAssertNil(clp2.count?[objectId])
        XCTAssertNil(clp2.addField?[objectId])

        let clp3 = try clp.setReadAccess(false, for: user)
        XCTAssertNil(clp3.get?[objectId])
        XCTAssertNil(clp3.find?[objectId])
        XCTAssertNil(clp3.create?[objectId])
        XCTAssertNil(clp3.update?[objectId])
        XCTAssertNil(clp3.delete?[objectId])
        XCTAssertNil(clp3.count?[objectId])
        XCTAssertNil(clp3.addField?[objectId])
    }

    func testReadAccessUserSetEncode() throws {
        let clp = try ParseCLP().setReadAccess(true, for: user)
        // swiftlint:disable:next line_length
        XCTAssertEqual(clp.description, "{\"count\":{\"\(objectId)\":true},\"find\":{\"\(objectId)\":true},\"get\":{\"\(objectId)\":true}}")
    }

    func testReadAccessPointerSet() throws {
        let clp = ParseCLP().setReadAccess(true, for: try user.toPointer())
        XCTAssertEqual(clp.get?[objectId], true)
        XCTAssertEqual(clp.find?[objectId], true)
        XCTAssertNil(clp.create?[objectId])
        XCTAssertNil(clp.update?[objectId])
        XCTAssertNil(clp.delete?[objectId])
        XCTAssertEqual(clp.count?[objectId], true)
        XCTAssertNil(clp.addField?[objectId])

        let clp2 = ParseCLP().setReadAccess(false, for: try user.toPointer())
        XCTAssertNil(clp2.get?[objectId])
        XCTAssertNil(clp2.find?[objectId])
        XCTAssertNil(clp2.create?[objectId])
        XCTAssertNil(clp2.update?[objectId])
        XCTAssertNil(clp2.delete?[objectId])
        XCTAssertNil(clp2.count?[objectId])
        XCTAssertNil(clp2.addField?[objectId])

        let clp3 = clp.setReadAccess(false, for: try user.toPointer())
        XCTAssertNil(clp3.get?[objectId])
        XCTAssertNil(clp3.find?[objectId])
        XCTAssertNil(clp3.create?[objectId])
        XCTAssertNil(clp3.update?[objectId])
        XCTAssertNil(clp3.delete?[objectId])
        XCTAssertNil(clp3.count?[objectId])
        XCTAssertNil(clp3.addField?[objectId])
    }

    func testReadAccessPointerSetEncode() throws {
        let clp = ParseCLP().setReadAccess(true,
                                           for: try user.toPointer())
        // swiftlint:disable:next line_length
        XCTAssertEqual(clp.description, "{\"count\":{\"\(objectId)\":true},\"find\":{\"\(objectId)\":true},\"get\":{\"\(objectId)\":true}}")
    }

    func testReadAccessRoleSet() throws {
        let name = "hello"
        let role = try Role<User>(name: name)
        let roleName = try ParseACL.getRoleAccessName(role)
        let clp = try ParseCLP().setReadAccess(true, for: role)
        XCTAssertEqual(clp.get?[roleName], true)
        XCTAssertEqual(clp.find?[roleName], true)
        XCTAssertNil(clp.create?[roleName])
        XCTAssertNil(clp.update?[roleName])
        XCTAssertNil(clp.delete?[roleName])
        XCTAssertEqual(clp.count?[roleName], true)
        XCTAssertNil(clp.addField?[roleName])

        let clp2 = try ParseCLP().setReadAccess(false, for: role)
        XCTAssertNil(clp2.get?[roleName])
        XCTAssertNil(clp2.find?[roleName])
        XCTAssertNil(clp2.create?[roleName])
        XCTAssertNil(clp2.update?[roleName])
        XCTAssertNil(clp2.delete?[roleName])
        XCTAssertNil(clp2.count?[roleName])
        XCTAssertNil(clp2.addField?[roleName])

        let clp3 = try clp.setReadAccess(false, for: role)
        XCTAssertNil(clp3.get?[roleName])
        XCTAssertNil(clp3.find?[roleName])
        XCTAssertNil(clp3.create?[roleName])
        XCTAssertNil(clp3.update?[roleName])
        XCTAssertNil(clp3.delete?[roleName])
        XCTAssertNil(clp3.count?[roleName])
        XCTAssertNil(clp3.addField?[roleName])
    }

    func testReadAccessRoleSetEncode() throws {
        let name = "hello"
        let role = try Role<User>(name: name)
        let roleName = try ParseACL.getRoleAccessName(role)
        let clp = try ParseCLP().setReadAccess(true,
                                               for: role)
        XCTAssertEqual(clp.description,
                       // swiftlint:disable:next line_length
                       "{\"count\":{\"\(roleName)\":true},\"find\":{\"\(roleName)\":true},\"get\":{\"\(roleName)\":true}}")
    }

    func testReadAccessPublicHas() throws {
        let clp = ParseCLP().setReadAccessPublic(true)
        XCTAssertTrue(clp.hasReadAccessPublic())
        XCTAssertFalse(clp.hasReadAccessRequiresAuthentication())

        let clp2 = ParseCLP().setReadAccessPublic(false)
        XCTAssertFalse(clp2.hasReadAccessPublic())
        XCTAssertFalse(clp2.hasReadAccessRequiresAuthentication())

        let clp3 = clp.setReadAccessPublic(false)
        XCTAssertFalse(clp3.hasReadAccessPublic())
        XCTAssertFalse(clp3.hasReadAccessRequiresAuthentication())
    }

    func testReadAccessRequiresAuthenticationHas() throws {
        let clp = ParseCLP().setReadAccessRequiresAuthentication(true)
        XCTAssertTrue(clp.hasReadAccessRequiresAuthentication())
        XCTAssertFalse(clp.hasReadAccessPublic())

        let clp2 = ParseCLP().setReadAccessRequiresAuthentication(false)
        XCTAssertFalse(clp2.hasReadAccessRequiresAuthentication())
        XCTAssertFalse(clp2.hasReadAccessPublic())

        let clp3 = clp.setReadAccessRequiresAuthentication(false)
        XCTAssertFalse(clp3.hasReadAccessRequiresAuthentication())
        XCTAssertFalse(clp3.hasReadAccessPublic())
    }

    func testReadAccessObjectIdHas() throws {
        let clp = ParseCLP().setReadAccess(true, for: objectId)
        XCTAssertTrue(clp.hasReadAccess(objectId))
        XCTAssertFalse(clp.hasWriteAccess(objectId))

        let clp2 = ParseCLP().setReadAccess(false, for: objectId)
        XCTAssertFalse(clp2.hasReadAccess(objectId))
        XCTAssertFalse(clp2.hasWriteAccess(objectId))

        let clp3 = clp.setReadAccess(false, for: objectId)
        XCTAssertFalse(clp3.hasReadAccess(objectId))
        XCTAssertFalse(clp3.hasWriteAccess(objectId))
    }

    func testReadAccessUserHas() throws {
        let clp = try ParseCLP().setReadAccess(true, for: user)
        XCTAssertTrue(try clp.hasReadAccess(user))
        XCTAssertFalse(try clp.hasWriteAccess(user))

        let clp2 = try ParseCLP().setReadAccess(false, for: user)
        XCTAssertFalse(try clp2.hasReadAccess(user))
        XCTAssertFalse(try clp2.hasWriteAccess(user))

        let clp3 = try clp.setReadAccess(false, for: user)
        XCTAssertFalse(try clp3.hasReadAccess(user))
        XCTAssertFalse(try clp3.hasWriteAccess(user))
    }

    func testReadAccessPointerHas() throws {
        let clp = ParseCLP().setReadAccess(true, for: try user.toPointer())
        XCTAssertTrue(clp.hasReadAccess(try user.toPointer()))
        XCTAssertFalse(clp.hasWriteAccess(try user.toPointer()))

        let clp2 = ParseCLP().setReadAccess(false, for: try user.toPointer())
        XCTAssertFalse(clp2.hasReadAccess(try user.toPointer()))
        XCTAssertFalse(clp2.hasWriteAccess(try user.toPointer()))

        let clp3 = clp.setReadAccess(false, for: try user.toPointer())
        XCTAssertFalse(clp3.hasReadAccess(try user.toPointer()))
        XCTAssertFalse(clp3.hasWriteAccess(try user.toPointer()))
    }

    func testReadAccessRoleHas() throws {
        let name = "hello"
        let role = try Role<User>(name: name)
        let clp = try ParseCLP().setReadAccess(true, for: role)
        XCTAssertTrue(try clp.hasReadAccess(role))
        XCTAssertFalse(try clp.hasWriteAccess(role))

        let clp2 = try ParseCLP().setReadAccess(false, for: role)
        XCTAssertFalse(try clp2.hasReadAccess(role))
        XCTAssertFalse(try clp2.hasWriteAccess(role))

        let clp3 = try clp.setReadAccess(false, for: role)
        XCTAssertFalse(try clp3.hasReadAccess(role))
        XCTAssertFalse(try clp3.hasWriteAccess(role))
    }
}
