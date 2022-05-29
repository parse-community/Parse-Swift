//
//  ParseSchemaTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 5/29/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class ParseSchemaTests: XCTestCase { // swiftlint:disable:this type_body_length
    struct GameScore: ParseObject {
        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var score: Double?
        var originalData: Data?

        //: Your own properties
        var points: Int

        //: a custom initializer
        init() {
            self.points = 5
        }
        init(points: Int) {
            self.points = points
        }
    }

    struct GameScore2: ParseObject {
        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var score: Double?
        var originalData: Data?

        //: Your own properties
        var points: Int

        //: a custom initializer
        init() {
            self.points = 10
        }
        init(points: Int) {
            self.points = points
        }
        init(objectId: String, points: Int) {
            self.objectId = objectId
            self.points = points
        }
    }

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

    func testInitializer() throws {
        let clp = ParseCLP(requiresAuthentication: true, publicAccess: true)
        let schema = ParseSchema<GameScore>(classLevelPermissions: clp)
        XCTAssertEqual(schema.className, GameScore.className)
        XCTAssertEqual(schema.classLevelPermissions, clp)
    }

    func testAddField() throws {
        let schema = ParseSchema<GameScore>()
            .addField("a",
                      type: .string,
                      options: ParseFieldOptions<String>(required: false, defauleValue: nil))
            .addField("b",
                      type: .pointer,
                      options: ParseFieldOptions<String>(required: false, defauleValue: nil))
            .addField("c",
                      type: .date,
                      options: ParseFieldOptions<String>(required: false, defauleValue: nil))
            .addField("d",
                      type: .acl,
                      options: ParseFieldOptions<String>(required: false, defauleValue: nil))
            .addField("e",
                      type: .array,
                      options: ParseFieldOptions<String>(required: false, defauleValue: nil))
            .addField("f",
                      type: .bytes,
                      options: ParseFieldOptions<String>(required: false, defauleValue: nil))
            .addField("g",
                      type: .object,
                      options: ParseFieldOptions<String>(required: false, defauleValue: nil))
            .addField("h",
                      type: .file,
                      options: ParseFieldOptions<String>(required: false, defauleValue: nil))
            .addField("i",
                      type: .geoPoint,
                      options: ParseFieldOptions<String>(required: false, defauleValue: nil))
            .addField("j",
                      type: .relation,
                      options: ParseFieldOptions<String>(required: false, defauleValue: nil))
            .addField("k",
                      type: .polygon,
                      options: ParseFieldOptions<String>(required: false, defauleValue: nil))
            .addField("l",
                      type: .boolean,
                      options: ParseFieldOptions<String>(required: false, defauleValue: nil))
            .addField("m",
                      type: .number,
                      options: ParseFieldOptions<String>(required: false, defauleValue: nil))
        XCTAssertEqual(schema.fields?["a"]?.type, .string)
        XCTAssertEqual(schema.fields?["b"]?.type, .pointer)
        XCTAssertEqual(schema.fields?["c"]?.type, .date)
        XCTAssertEqual(schema.fields?["d"]?.type, .acl)
        XCTAssertEqual(schema.fields?["e"]?.type, .array)
        XCTAssertEqual(schema.fields?["f"]?.type, .bytes)
        XCTAssertEqual(schema.fields?["g"]?.type, .object)
        XCTAssertEqual(schema.fields?["h"]?.type, .file)
        XCTAssertEqual(schema.fields?["i"]?.type, .geoPoint)
        XCTAssertEqual(schema.fields?["j"]?.type, .relation)
        XCTAssertEqual(schema.fields?["k"]?.type, .polygon)
        XCTAssertEqual(schema.fields?["l"]?.type, .boolean)
        XCTAssertEqual(schema.fields?["m"]?.type, .number)
    }

    func testAddPointer() throws {
        let gameScore2 = GameScore2(objectId: "yolo", points: 12)
        let options = try ParseFieldOptions<GameScore2>(required: false, defauleValue: gameScore2)
        let schema = ParseSchema<GameScore>()
            .addPointer("a",
                        options: options)
        XCTAssertEqual(schema.fields?["a"]?.type, .pointer)
        XCTAssertEqual(schema.fields?["a"]?.targetClass, gameScore2.className)
    }

    func testAddRelation() throws {
        let options = try ParseFieldOptions<GameScore2>(required: false, defauleValue: nil)
        let schema = ParseSchema<GameScore>()
            .addRelation("a",
                         options: options)
        XCTAssertEqual(schema.fields?["a"]?.type, .relation)
        XCTAssertEqual(schema.fields?["a"]?.targetClass, GameScore2().className)
    }

    func testDeleteField() throws {
        var schema = ParseSchema<GameScore>()
            .addField("a",
                      type: .string,
                      options: ParseFieldOptions<String>(required: false, defauleValue: nil))
            .deleteField("a")
        let delete = ParseField(operation: .delete)
        XCTAssertEqual(schema.fields?["a"], delete)

        schema = schema.deleteField("b")
        XCTAssertEqual(schema.fields?["a"], delete)
        XCTAssertEqual(schema.fields?["b"], delete)
    }
}
