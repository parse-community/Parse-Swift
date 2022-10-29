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
        var points: Int?

        //: a custom initializer
        init() { }
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
        var points: Int?

        //: Custom initializers
        init() { }

        init(points: Int) {
            self.points = points
        }

        init(objectId: String, points: Int) {
            self.objectId = objectId
            self.points = points
        }
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

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        MockURLProtocol.removeAll()
        #if !os(Linux) && !os(Android) && !os(Windows)
        try KeychainStore.shared.deleteAll()
        #endif
        try ParseStorage.shared.deleteAll()
    }

    func createDummySchema() -> ParseSchema<GameScore> {
        let fields = Set<String>(["world"])
        let clp = ParseCLP()
            .setPointerFields(fields, on: .create)
            .setWriteAccessPublic(true, canAddField: true)

        let schema = ParseSchema<GameScore>(classLevelPermissions: clp)
            .addField("a",
                      type: .string,
                      options: ParseFieldOptions<String>(required: false, defauleValue: nil))
            .addField("b",
                      type: .number,
                      options: ParseFieldOptions<Int>(required: false, defauleValue: 2))
            .deleteField("c")
            .addIndex("hello", field: "world", index: "yolo")
        return schema
    }

    func testInitializer() throws {
        let clp = ParseCLP(requiresAuthentication: true, publicAccess: true)
        let schema = ParseSchema<GameScore>(classLevelPermissions: clp)
        XCTAssertEqual(schema.className, GameScore.className)
        XCTAssertEqual(ParseSchema<GameScore>.className, GameScore.className)
        XCTAssertEqual(schema.classLevelPermissions, clp)
    }

    func testParseFieldOptionsEncode() {
        let options = ParseFieldOptions<Int>(required: false, defauleValue: 2)
        XCTAssertEqual(options.description,
                       "{\"defaultValue\":2,\"required\":false}")
    }

    func testSchemaEncode() throws {
        let schema = createDummySchema()
        // swiftlint:disable:next line_length
        let expected = "{\"classLevelPermissions\":{\"addField\":{\"*\":true},\"create\":{\"*\":true,\"pointerFields\":[\"world\"]},\"delete\":{\"*\":true},\"update\":{\"*\":true}},\"className\":\"GameScore\",\"fields\":{\"a\":{\"required\":false,\"type\":\"String\"},\"b\":{\"defaultValue\":2,\"required\":false,\"type\":\"Number\"},\"c\":{\"__op\":\"Delete\"}}}"
        XCTAssertEqual(schema.description, expected)
    }

    func testAddField() throws {
        let options = try ParseFieldOptions<GameScore2>(required: false, defauleValue: nil)
        let schema = try ParseSchema<GameScore>()
            .addField("a",
                      type: .string,
                      options: ParseFieldOptions<String>(required: false, defauleValue: nil))
            .addField("b",
                      type: .pointer,
                      options: options)
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
                      options: options)
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

    func testAddFieldWrongOptionsError() throws {
        let options = try ParseFieldOptions<GameScore2>(required: false, defauleValue: nil)
        XCTAssertThrowsError(try ParseSchema<GameScore>()
            .addField("b",
                      type: .string,
                      options: options))
    }

    func testGetFields() throws {
        let schema = ParseSchema<GameScore>()
            .addField("a",
                      type: .string,
                      options: ParseFieldOptions<String>(required: false, defauleValue: nil))
            .addField("b",
                      type: .number,
                      options: ParseFieldOptions<Int>(required: false, defauleValue: 2))
        let fields = schema.getFields()
        XCTAssertEqual(fields["a"], "{\"required\":false,\"type\":\"String\"}")
        XCTAssertEqual(fields["b"], "{\"defaultValue\":2,\"required\":false,\"type\":\"Number\"}")
    }

    func testAddPointer() throws {
        let gameScore2 = GameScore2(objectId: "yolo", points: 12)
        let options = try ParseFieldOptions<GameScore2>(required: false, defauleValue: gameScore2)
        let schema = ParseSchema<GameScore>()
            .addPointer("a",
                        options: options)
        XCTAssertEqual(schema.fields?["a"]?.type, .pointer)
        XCTAssertEqual(schema.fields?["a"]?.targetClass, gameScore2.className)
        guard let value = schema.fields?["a"]?.defaultValue?.value as? GameScore2 else {
            XCTFail("Should have unwrapped")
            return
        }
        XCTAssertEqual(try value.toPointer(), try gameScore2.toPointer())

        let schema2 = schema.addPointer("b",
                                        options: options)
        XCTAssertEqual(schema2.fields?["b"]?.type, .pointer)
        XCTAssertEqual(schema2.fields?["b"]?.targetClass, gameScore2.className)
        guard let value2 = schema2.fields?["b"]?.defaultValue?.value as? GameScore2 else {
            XCTFail("Should have unwrapped")
            return
        }
        XCTAssertEqual(try value2.toPointer(), try gameScore2.toPointer())
    }

    func testAddRelation() throws {
        let options = try ParseFieldOptions<GameScore2>(required: false, defauleValue: nil)
        let schema = ParseSchema<GameScore>()
            .addRelation("a",
                         options: options)
        XCTAssertEqual(schema.fields?["a"]?.type, .relation)
        XCTAssertEqual(schema.fields?["a"]?.targetClass, GameScore2.className)

        let schema2 = schema.addRelation("b",
                                         options: options)
        XCTAssertEqual(schema2.fields?["b"]?.type, .relation)
        XCTAssertEqual(schema2.fields?["b"]?.targetClass, GameScore2.className)
    }

    func testDeleteField() throws {
        var schema = ParseSchema<GameScore>()
            .deleteField("a")
        let delete = ParseField(operation: .delete)
        XCTAssertEqual(schema.fields?["a"], delete)

        schema = schema.deleteField("b")
        XCTAssertEqual(schema.fields?["a"], delete)
        XCTAssertEqual(schema.fields?["b"], delete)
    }

    func testAddIndexes() throws {
        let schema = ParseSchema<GameScore>()
            .addIndex("hello", field: "world", index: "yolo")
            .addIndex("next", field: "place", index: "home")
        let indexes = schema.getIndexes()
        guard let firstIndex = indexes["hello"]?["world"],
            let secondIndex = indexes["next"]?["place"] else {
            XCTFail("Should have unwrapped")
            return
        }
        XCTAssertEqual(firstIndex, "yolo")
        XCTAssertEqual(secondIndex, "home")

        let alreadyStoredIndexes: [String: [String: AnyCodable]] = [
            "meta": ["world": "peace"],
            "stop": ["being": "greedy"]
        ]
        var schema2 = ParseSchema<GameScore>()
        schema2.indexes = alreadyStoredIndexes
        let indexes2 = schema2.getIndexes()
        guard let firstIndex2 = indexes2["meta"]?["world"],
            let secondIndex2 = indexes2["stop"]?["being"] else {
            XCTFail("Should have unwrapped")
            return
        }
        XCTAssertEqual(firstIndex2, "peace")
        XCTAssertEqual(secondIndex2, "greedy")

        schema2 = schema2
            .addIndex("hello", field: "world", index: "yolo")
            .addIndex("next", field: "place", index: "home")
        let indexes3 = schema2.getIndexes()
        guard let firstIndex3 = indexes3["meta"]?["world"],
            let secondIndex3 = indexes3["stop"]?["being"],
            let thirdIndex3 = indexes["hello"]?["world"],
            let fourthIndex3 = indexes["next"]?["place"] else {
            XCTFail("Should have unwrapped")
            return
        }
        XCTAssertEqual(firstIndex3, "peace")
        XCTAssertEqual(secondIndex3, "greedy")
        XCTAssertEqual(thirdIndex3, "yolo")
        XCTAssertEqual(fourthIndex3, "home")
    }

    func testDeleteIndexes() throws {
        let schema = ParseSchema<GameScore>()
            .deleteIndex("hello")
            .addIndex("next", field: "place", index: "home")
        let indexes = schema.getIndexes()
        guard let firstIndex = indexes["hello"]?["__op"],
            let secondIndex = indexes["next"]?["place"] else {
            XCTFail("Should have unwrapped")
            return
        }
        XCTAssertEqual(firstIndex, "Delete")
        XCTAssertEqual(secondIndex, "home")
    }
}
