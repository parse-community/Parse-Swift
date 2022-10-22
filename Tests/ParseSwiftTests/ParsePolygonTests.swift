//
//  ParsePolygonTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 7/9/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import XCTest
@testable import ParseSwift

class ParsePolygonTests: XCTestCase {

    struct FakeParsePolygon: Encodable, Hashable {
        private let __type: String = "Polygon" // swiftlint:disable:this identifier_name
        public let coordinates: [[Double]]
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
        points = [
            try ParseGeoPoint(latitude: 0, longitude: 0),
            try ParseGeoPoint(latitude: 0, longitude: 1),
            try ParseGeoPoint(latitude: 1, longitude: 1),
            try ParseGeoPoint(latitude: 1, longitude: 0),
            try ParseGeoPoint(latitude: 0, longitude: 0)
        ]
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        MockURLProtocol.removeAll()
        #if !os(Linux) && !os(Android) && !os(Windows)
        try KeychainStore.shared.deleteAll()
        #endif
        try ParseStorage.shared.deleteAll()
    }

    var points = [ParseGeoPoint]()

    func testContainsPoint() throws {
        let polygon = try ParsePolygon(points)
        let inside = try ParseGeoPoint(latitude: 0.5, longitude: 0.5)
        let outside = try ParseGeoPoint(latitude: 10, longitude: 10)
        XCTAssertTrue(polygon.containsPoint(inside))
        XCTAssertFalse(polygon.containsPoint(outside))
    }

    func testCheckInitializerRequiresMinPoints() throws {
        let point = try ParseGeoPoint(latitude: 0, longitude: 0)
        XCTAssertNoThrow(try ParsePolygon([point, point, point]))
        XCTAssertThrowsError(try ParsePolygon([point, point]))
        XCTAssertNoThrow(try ParsePolygon(point, point, point))
        XCTAssertThrowsError(try ParsePolygon(point, point))
    }

    func testDecode() throws {
        let polygon = try ParsePolygon(points)
        let encoded = try ParseCoding.jsonEncoder().encode(polygon)
        let decoded = try ParseCoding.jsonDecoder().decode(ParsePolygon.self, from: encoded)
        XCTAssertEqual(decoded, polygon)
    }

    func testDecodeFailNotEnoughPoints() throws {
        let fakePolygon = FakeParsePolygon(coordinates: [[0.0, 0.0], [0.0, 1.0]])
        let encoded = try ParseCoding.jsonEncoder().encode(fakePolygon)
        do {
            _ = try ParseCoding.jsonDecoder().decode(ParsePolygon.self, from: encoded)
            XCTFail("Should have failed")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have unwrapped")
                return
            }
            XCTAssertTrue(parseError.message.contains("3 ParseGeoPoint"))
        }
    }

    func testDecodeFailWrongData() throws {
        let fakePolygon = FakeParsePolygon(coordinates: [[0.0], [1.0]])
        let encoded = try ParseCoding.jsonEncoder().encode(fakePolygon)
        do {
            _ = try ParseCoding.jsonDecoder().decode(ParsePolygon.self, from: encoded)
            XCTFail("Should have failed")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have unwrapped")
                return
            }
            XCTAssertTrue(parseError.message.contains("decode ParsePolygon"))
        }
    }

    func testDecodeFailTooMuchCoordinates() throws {
        let fakePolygon = FakeParsePolygon(coordinates: [[0.0, 0.0, 0.0], [0.0, 1.0, 1.0]])
        let encoded = try ParseCoding.jsonEncoder().encode(fakePolygon)
        do {
            _ = try ParseCoding.jsonDecoder().decode(ParsePolygon.self, from: encoded)
            XCTFail("Should have failed")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have unwrapped")
                return
            }
            XCTAssertTrue(parseError.message.contains("decode ParsePolygon"))
        }
    }

    func testDebugString() throws {
        let polygon = try ParsePolygon(points)
        let expected = "{\"__type\":\"Polygon\",\"coordinates\":[[0,0],[1,0],[1,1],[0,1],[0,0]]}"
        XCTAssertEqual(polygon.debugDescription, expected)
    }

    func testDescription() throws {
        let polygon = try ParsePolygon(points)
        let expected = "{\"__type\":\"Polygon\",\"coordinates\":[[0,0],[1,0],[1,1],[0,1],[0,0]]}"
        XCTAssertEqual(polygon.description, expected)
    }
}
