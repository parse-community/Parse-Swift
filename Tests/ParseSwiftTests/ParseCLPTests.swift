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
        init(objectId: String) {
            self.objectId = objectId
        }
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
                              masterKey: "masterKey",
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

    func testCLPInitializerRequiresAuthentication() throws {
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

    func testCLPInitializerPublicAccess() throws {
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

    func testCLPInitializerRequireAndPublicAccess() throws {
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

    func testCLPWriteAccessPublicSet() throws {
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

    func testCLPWriteAccessPublicSetEncode() throws {
        let clp = ParseCLP().setWriteAccessPublic(true, canAddField: true)
        // swiftlint:disable:next line_length
        XCTAssertEqual(clp.description, "ParseCLP ({\"addField\":{\"*\":true},\"create\":{\"*\":true},\"delete\":{\"*\":true},\"update\":{\"*\":true}})")
    }

    func testCLPWriteAccessRequiresAuthenticationSet() throws {
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

    func testCLPWriteAccessRequiresAuthenticationSetEncode() throws {
        let clp = ParseCLP().setWriteAccessRequiresAuthentication(true, canAddField: true)
        // swiftlint:disable:next line_length
        XCTAssertEqual(clp.description, "ParseCLP ({\"addField\":{\"requiresAuthentication\":true},\"create\":{\"requiresAuthentication\":true},\"delete\":{\"requiresAuthentication\":true},\"update\":{\"requiresAuthentication\":true}})")
    }

    func testCLPWriteAccessObjectIdSet() throws {
        let clp = ParseCLP().setWriteAccess(true, objectId: objectId)
        XCTAssertNil(clp.get?[objectId])
        XCTAssertNil(clp.find?[objectId])
        XCTAssertEqual(clp.create?[objectId], true)
        XCTAssertEqual(clp.update?[objectId], true)
        XCTAssertEqual(clp.delete?[objectId], true)
        XCTAssertNil(clp.count?[objectId])
        XCTAssertNil(clp.addField?[objectId])

        let clp2 = ParseCLP().setWriteAccess(true, objectId: objectId, canAddField: true)
        XCTAssertNil(clp2.get?[objectId])
        XCTAssertNil(clp2.find?[objectId])
        XCTAssertEqual(clp2.create?[objectId], true)
        XCTAssertEqual(clp2.update?[objectId], true)
        XCTAssertEqual(clp2.delete?[objectId], true)
        XCTAssertNil(clp2.count?[objectId])
        XCTAssertEqual(clp2.addField?[objectId], true)

        let clp3 = clp.setWriteAccess(false, objectId: objectId)
        XCTAssertNil(clp3.get?[objectId])
        XCTAssertNil(clp3.find?[objectId])
        XCTAssertNil(clp3.create?[objectId])
        XCTAssertNil(clp3.update?[objectId])
        XCTAssertNil(clp3.delete?[objectId])
        XCTAssertNil(clp3.count?[objectId])
        XCTAssertNil(clp3.addField?[objectId])

        let clp4 = clp2.setWriteAccess(false, objectId: objectId)
        XCTAssertNil(clp4.get?[objectId])
        XCTAssertNil(clp4.find?[objectId])
        XCTAssertNil(clp4.create?[objectId])
        XCTAssertNil(clp4.update?[objectId])
        XCTAssertNil(clp4.delete?[objectId])
        XCTAssertNil(clp4.count?[objectId])
        XCTAssertNil(clp4.addField?[objectId])
    }

    func testCLPWriteAccessObjectIdSetEncode() throws {
        let clp = ParseCLP().setWriteAccess(true, objectId: objectId, canAddField: true)
        // swiftlint:disable:next line_length
        XCTAssertEqual(clp.description, "ParseCLP ({\"addField\":{\"\(objectId)\":true},\"create\":{\"\(objectId)\":true},\"delete\":{\"\(objectId)\":true},\"update\":{\"\(objectId)\":true}})")
    }

    func testCLPWriteAccessUserSet() throws {
        let clp = try ParseCLP().setWriteAccess(true, user: user)
        XCTAssertNil(clp.get?[objectId])
        XCTAssertNil(clp.find?[objectId])
        XCTAssertEqual(clp.create?[objectId], true)
        XCTAssertEqual(clp.update?[objectId], true)
        XCTAssertEqual(clp.delete?[objectId], true)
        XCTAssertNil(clp.count?[objectId])
        XCTAssertNil(clp.addField?[objectId])

        let clp2 = try ParseCLP().setWriteAccess(true, user: user, canAddField: true)
        XCTAssertNil(clp2.get?[objectId])
        XCTAssertNil(clp2.find?[objectId])
        XCTAssertEqual(clp2.create?[objectId], true)
        XCTAssertEqual(clp2.update?[objectId], true)
        XCTAssertEqual(clp2.delete?[objectId], true)
        XCTAssertNil(clp2.count?[objectId])
        XCTAssertEqual(clp2.addField?[objectId], true)

        let clp3 = try clp.setWriteAccess(false, user: user)
        XCTAssertNil(clp3.get?[objectId])
        XCTAssertNil(clp3.find?[objectId])
        XCTAssertNil(clp3.create?[objectId])
        XCTAssertNil(clp3.update?[objectId])
        XCTAssertNil(clp3.delete?[objectId])
        XCTAssertNil(clp3.count?[objectId])
        XCTAssertNil(clp3.addField?[objectId])

        let clp4 = try clp2.setWriteAccess(false, user: user)
        XCTAssertNil(clp4.get?[objectId])
        XCTAssertNil(clp4.find?[objectId])
        XCTAssertNil(clp4.create?[objectId])
        XCTAssertNil(clp4.update?[objectId])
        XCTAssertNil(clp4.delete?[objectId])
        XCTAssertNil(clp4.count?[objectId])
        XCTAssertNil(clp4.addField?[objectId])
    }

    func testCLPWriteAccessUserSetEncode() throws {
        let clp = try ParseCLP().setWriteAccess(true, user: user, canAddField: true)
        // swiftlint:disable:next line_length
        XCTAssertEqual(clp.description, "ParseCLP ({\"addField\":{\"\(objectId)\":true},\"create\":{\"\(objectId)\":true},\"delete\":{\"\(objectId)\":true},\"update\":{\"\(objectId)\":true}})")
    }

    func testCLPWriteAccessPointerSet() throws {
        let clp = ParseCLP().setWriteAccess(true, user: try user.toPointer())
        XCTAssertNil(clp.get?[objectId])
        XCTAssertNil(clp.find?[objectId])
        XCTAssertEqual(clp.create?[objectId], true)
        XCTAssertEqual(clp.update?[objectId], true)
        XCTAssertEqual(clp.delete?[objectId], true)
        XCTAssertNil(clp.count?[objectId])
        XCTAssertNil(clp.addField?[objectId])

        let clp2 = ParseCLP().setWriteAccess(true,
                                             user: try user.toPointer(),
                                             canAddField: true)
        XCTAssertNil(clp2.get?[objectId])
        XCTAssertNil(clp2.find?[objectId])
        XCTAssertEqual(clp2.create?[objectId], true)
        XCTAssertEqual(clp2.update?[objectId], true)
        XCTAssertEqual(clp2.delete?[objectId], true)
        XCTAssertNil(clp2.count?[objectId])
        XCTAssertEqual(clp2.addField?[objectId], true)

        let clp3 = clp.setWriteAccess(false, user: try user.toPointer())
        XCTAssertNil(clp3.get?[objectId])
        XCTAssertNil(clp3.find?[objectId])
        XCTAssertNil(clp3.create?[objectId])
        XCTAssertNil(clp3.update?[objectId])
        XCTAssertNil(clp3.delete?[objectId])
        XCTAssertNil(clp3.count?[objectId])
        XCTAssertNil(clp3.addField?[objectId])

        let clp4 = clp2.setWriteAccess(false, user: try user.toPointer())
        XCTAssertNil(clp4.get?[objectId])
        XCTAssertNil(clp4.find?[objectId])
        XCTAssertNil(clp4.create?[objectId])
        XCTAssertNil(clp4.update?[objectId])
        XCTAssertNil(clp4.delete?[objectId])
        XCTAssertNil(clp4.count?[objectId])
        XCTAssertNil(clp4.addField?[objectId])
    }

    func testCLPWriteAccessPointerSetEncode() throws {
        let clp = ParseCLP().setWriteAccess(true,
                                            user: try user.toPointer(),
                                            canAddField: true)
        // swiftlint:disable:next line_length
        XCTAssertEqual(clp.description, "ParseCLP ({\"addField\":{\"\(objectId)\":true},\"create\":{\"\(objectId)\":true},\"delete\":{\"\(objectId)\":true},\"update\":{\"\(objectId)\":true}})")
    }

    func testCLPWriteAccessRoleSet() throws {
        let name = "hello"
        let role = try Role<User>(name: name)
        let roleName = try ParseACL.getRoleAccessName(role)
        let clp = try ParseCLP().setWriteAccess(true, role: role)
        XCTAssertNil(clp.get?[roleName])
        XCTAssertNil(clp.find?[roleName])
        XCTAssertEqual(clp.create?[roleName], true)
        XCTAssertEqual(clp.update?[roleName], true)
        XCTAssertEqual(clp.delete?[roleName], true)
        XCTAssertNil(clp.count?[roleName])
        XCTAssertNil(clp.addField?[roleName])

        let clp2 = try ParseCLP().setWriteAccess(true,
                                                 role: role,
                                                 canAddField: true)
        XCTAssertNil(clp2.get?[roleName])
        XCTAssertNil(clp2.find?[roleName])
        XCTAssertEqual(clp2.create?[roleName], true)
        XCTAssertEqual(clp2.update?[roleName], true)
        XCTAssertEqual(clp2.delete?[roleName], true)
        XCTAssertNil(clp2.count?[roleName])
        XCTAssertEqual(clp2.addField?[roleName], true)

        let clp3 = try clp.setWriteAccess(false, role: role)
        XCTAssertNil(clp3.get?[roleName])
        XCTAssertNil(clp3.find?[roleName])
        XCTAssertNil(clp3.create?[roleName])
        XCTAssertNil(clp3.update?[roleName])
        XCTAssertNil(clp3.delete?[roleName])
        XCTAssertNil(clp3.count?[roleName])
        XCTAssertNil(clp3.addField?[roleName])

        let clp4 = try clp2.setWriteAccess(false, role: role)
        XCTAssertNil(clp4.get?[roleName])
        XCTAssertNil(clp4.find?[roleName])
        XCTAssertNil(clp4.create?[roleName])
        XCTAssertNil(clp4.update?[roleName])
        XCTAssertNil(clp4.delete?[roleName])
        XCTAssertNil(clp4.count?[roleName])
        XCTAssertNil(clp4.addField?[roleName])
    }

    func testCLPWriteAccessRoleSetEncode() throws {
        let name = "hello"
        let role = try Role<User>(name: name)
        let roleName = try ParseACL.getRoleAccessName(role)
        let clp = try ParseCLP().setWriteAccess(true,
                                                role: role,
                                                canAddField: true)
        // swiftlint:disable:next line_length
        XCTAssertEqual(clp.description, "ParseCLP ({\"addField\":{\"\(roleName)\":true},\"create\":{\"\(roleName)\":true},\"delete\":{\"\(roleName)\":true},\"update\":{\"\(roleName)\":true}})")
    }

    func testCLPReadAccessPublicSet() throws {
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

    func testCLPReadAccessPublicSetEncode() throws {
        let clp = ParseCLP().setReadAccessPublic(true)
        // swiftlint:disable:next line_length
        XCTAssertEqual(clp.description, "ParseCLP ({\"count\":{\"*\":true},\"find\":{\"*\":true},\"get\":{\"*\":true}})")
    }

    func testCLPReadAccessRequiresAuthenticationSet() throws {
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

    func testCLPReadAccessRequiresAuthenticationSetEncode() throws {
        let clp = ParseCLP().setReadAccessRequiresAuthentication(true)
        // swiftlint:disable:next line_length
        XCTAssertEqual(clp.description, "ParseCLP ({\"count\":{\"requiresAuthentication\":true},\"find\":{\"requiresAuthentication\":true},\"get\":{\"requiresAuthentication\":true}})")
    }

    func testCLPReadAccessObjectIdSet() throws {
        let clp = ParseCLP().setReadAccess(true, objectId: objectId)
        XCTAssertEqual(clp.get?[objectId], true)
        XCTAssertEqual(clp.find?[objectId], true)
        XCTAssertNil(clp.create?[objectId])
        XCTAssertNil(clp.update?[objectId])
        XCTAssertNil(clp.delete?[objectId])
        XCTAssertEqual(clp.count?[objectId], true)
        XCTAssertNil(clp.addField?[objectId])

        let clp2 = ParseCLP().setReadAccess(false, objectId: objectId)
        XCTAssertNil(clp2.get?[objectId])
        XCTAssertNil(clp2.find?[objectId])
        XCTAssertNil(clp2.create?[objectId])
        XCTAssertNil(clp2.update?[objectId])
        XCTAssertNil(clp2.delete?[objectId])
        XCTAssertNil(clp2.count?[objectId])
        XCTAssertNil(clp2.addField?[objectId])

        let clp3 = clp.setReadAccess(false, objectId: objectId)
        XCTAssertNil(clp3.get?[objectId])
        XCTAssertNil(clp3.find?[objectId])
        XCTAssertNil(clp3.create?[objectId])
        XCTAssertNil(clp3.update?[objectId])
        XCTAssertNil(clp3.delete?[objectId])
        XCTAssertNil(clp3.count?[objectId])
        XCTAssertNil(clp3.addField?[objectId])
    }

    func testCLPReadAccessObjectIdSetEncode() throws {
        let clp = ParseCLP().setReadAccess(true, objectId: objectId)
        // swiftlint:disable:next line_length
        XCTAssertEqual(clp.description, "ParseCLP ({\"count\":{\"\(objectId)\":true},\"find\":{\"\(objectId)\":true},\"get\":{\"\(objectId)\":true}})")
    }

    func testCLPReadAccessUserSet() throws {
        let clp = try ParseCLP().setReadAccess(true, user: user)
        XCTAssertEqual(clp.get?[objectId], true)
        XCTAssertEqual(clp.find?[objectId], true)
        XCTAssertNil(clp.create?[objectId])
        XCTAssertNil(clp.update?[objectId])
        XCTAssertNil(clp.delete?[objectId])
        XCTAssertEqual(clp.count?[objectId], true)
        XCTAssertNil(clp.addField?[objectId])

        let clp2 = try ParseCLP().setReadAccess(false, user: user)
        XCTAssertNil(clp2.get?[objectId])
        XCTAssertNil(clp2.find?[objectId])
        XCTAssertNil(clp2.create?[objectId])
        XCTAssertNil(clp2.update?[objectId])
        XCTAssertNil(clp2.delete?[objectId])
        XCTAssertNil(clp2.count?[objectId])
        XCTAssertNil(clp2.addField?[objectId])

        let clp3 = try clp.setReadAccess(false, user: user)
        XCTAssertNil(clp3.get?[objectId])
        XCTAssertNil(clp3.find?[objectId])
        XCTAssertNil(clp3.create?[objectId])
        XCTAssertNil(clp3.update?[objectId])
        XCTAssertNil(clp3.delete?[objectId])
        XCTAssertNil(clp3.count?[objectId])
        XCTAssertNil(clp3.addField?[objectId])
    }

    func testCLPReadAccessUserSetEncode() throws {
        let clp = try ParseCLP().setReadAccess(true, user: user)
        // swiftlint:disable:next line_length
        XCTAssertEqual(clp.description, "ParseCLP ({\"count\":{\"\(objectId)\":true},\"find\":{\"\(objectId)\":true},\"get\":{\"\(objectId)\":true}})")
    }

    func testCLPReadAccessPointerSet() throws {
        let clp = ParseCLP().setReadAccess(true, user: try user.toPointer())
        XCTAssertEqual(clp.get?[objectId], true)
        XCTAssertEqual(clp.find?[objectId], true)
        XCTAssertNil(clp.create?[objectId])
        XCTAssertNil(clp.update?[objectId])
        XCTAssertNil(clp.delete?[objectId])
        XCTAssertEqual(clp.count?[objectId], true)
        XCTAssertNil(clp.addField?[objectId])

        let clp2 = ParseCLP().setReadAccess(false, user: try user.toPointer())
        XCTAssertNil(clp2.get?[objectId])
        XCTAssertNil(clp2.find?[objectId])
        XCTAssertNil(clp2.create?[objectId])
        XCTAssertNil(clp2.update?[objectId])
        XCTAssertNil(clp2.delete?[objectId])
        XCTAssertNil(clp2.count?[objectId])
        XCTAssertNil(clp2.addField?[objectId])

        let clp3 = clp.setReadAccess(false, user: try user.toPointer())
        XCTAssertNil(clp3.get?[objectId])
        XCTAssertNil(clp3.find?[objectId])
        XCTAssertNil(clp3.create?[objectId])
        XCTAssertNil(clp3.update?[objectId])
        XCTAssertNil(clp3.delete?[objectId])
        XCTAssertNil(clp3.count?[objectId])
        XCTAssertNil(clp3.addField?[objectId])
    }

    func testCLPReadAccessPointerSetEncode() throws {
        let clp = ParseCLP().setReadAccess(true,
                                           user: try user.toPointer())
        // swiftlint:disable:next line_length
        XCTAssertEqual(clp.description, "ParseCLP ({\"count\":{\"\(objectId)\":true},\"find\":{\"\(objectId)\":true},\"get\":{\"\(objectId)\":true}})")
    }

    func testCLPReadAccessRoleSet() throws {
        let name = "hello"
        let role = try Role<User>(name: name)
        let roleName = try ParseACL.getRoleAccessName(role)
        let clp = try ParseCLP().setReadAccess(true, role: role)
        XCTAssertEqual(clp.get?[roleName], true)
        XCTAssertEqual(clp.find?[roleName], true)
        XCTAssertNil(clp.create?[roleName])
        XCTAssertNil(clp.update?[roleName])
        XCTAssertNil(clp.delete?[roleName])
        XCTAssertEqual(clp.count?[roleName], true)
        XCTAssertNil(clp.addField?[roleName])

        let clp2 = try ParseCLP().setReadAccess(false, role: role)
        XCTAssertNil(clp2.get?[roleName])
        XCTAssertNil(clp2.find?[roleName])
        XCTAssertNil(clp2.create?[roleName])
        XCTAssertNil(clp2.update?[roleName])
        XCTAssertNil(clp2.delete?[roleName])
        XCTAssertNil(clp2.count?[roleName])
        XCTAssertNil(clp2.addField?[roleName])

        let clp3 = try clp.setReadAccess(false, role: role)
        XCTAssertNil(clp3.get?[roleName])
        XCTAssertNil(clp3.find?[roleName])
        XCTAssertNil(clp3.create?[roleName])
        XCTAssertNil(clp3.update?[roleName])
        XCTAssertNil(clp3.delete?[roleName])
        XCTAssertNil(clp3.count?[roleName])
        XCTAssertNil(clp3.addField?[roleName])
    }

    func testCLPReadAccessRoleSetEncode() throws {
        let name = "hello"
        let role = try Role<User>(name: name)
        let roleName = try ParseACL.getRoleAccessName(role)
        let clp = try ParseCLP().setReadAccess(true,
                                               role: role)
        // swiftlint:disable:next line_length
        XCTAssertEqual(clp.description, "ParseCLP ({\"count\":{\"\(roleName)\":true},\"find\":{\"\(roleName)\":true},\"get\":{\"\(roleName)\":true}})")
    }
}
