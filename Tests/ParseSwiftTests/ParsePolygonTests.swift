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
        #if !os(Linux) && !os(Android)
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

    #if !os(Linux) && !os(Android)
    func testDebugString() throws {
        let polygon = try ParsePolygon(points)
        // swiftlint:disable:next line_length
        let expected = "ParsePolygon ({\"__type\":\"Polygon\",\"coordinates\":[{\"__type\":\"GeoPoint\",\"longitude\":0,\"latitude\":0},{\"__type\":\"GeoPoint\",\"longitude\":1,\"latitude\":0},{\"__type\":\"GeoPoint\",\"longitude\":1,\"latitude\":1},{\"__type\":\"GeoPoint\",\"longitude\":0,\"latitude\":1},{\"__type\":\"GeoPoint\",\"longitude\":0,\"latitude\":0}]})"
        XCTAssertEqual(polygon.debugDescription, expected)
    }

    func testDescription() throws {
        let polygon = try ParsePolygon(points)
        // swiftlint:disable:next line_length
        let expected = "ParsePolygon ({\"__type\":\"Polygon\",\"coordinates\":[{\"__type\":\"GeoPoint\",\"longitude\":0,\"latitude\":0},{\"__type\":\"GeoPoint\",\"longitude\":1,\"latitude\":0},{\"__type\":\"GeoPoint\",\"longitude\":1,\"latitude\":1},{\"__type\":\"GeoPoint\",\"longitude\":0,\"latitude\":1},{\"__type\":\"GeoPoint\",\"longitude\":0,\"latitude\":0}]})"
        XCTAssertEqual(polygon.description, expected)
    }
    #endif
}
