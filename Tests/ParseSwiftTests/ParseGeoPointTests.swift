//
//  ParseGeoPointTests.swift
//  ParseSwiftTests
//
//  Created by Corey Baker on 9/21/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

#if !os(watchOS)
import XCTest
#if canImport(CoreLocation)
import CoreLocation
#endif
@testable import ParseSwift

class ParseGeoPointTests: XCTestCase {
    override func setUp() {
        super.setUp()
        guard let url = URL(string: "http://localhost:1337/1") else {
            XCTFail("Should create valid URL")
            return
        }
        ParseSwift.initialize(applicationId: "applicationId",
                              clientKey: "clientKey",
                              masterKey: "masterKey",
                              serverURL: url)
    }

    override func tearDown() {
        super.tearDown()
        MockURLProtocol.removeAll()
        try? KeychainStore.shared.deleteAll()
        try? ParseStorage.shared.deleteAll()
    }

    func testDefaults() {
        let point = GeoPoint()
        // Check default values
        XCTAssertEqual(point.latitude, 0.0, accuracy: 0.00001, "Latitude should be 0.0")
        XCTAssertEqual(point.longitude, 0.0, accuracy: 0.00001, "Longitude should be 0.0")
    }

    #if canImport(CoreLocation)
    func testGeoPointFromLocation() {
        let location = CLLocation(latitude: 10.0, longitude: 20.0)
        let geoPoint = GeoPoint(location: location)
        XCTAssertEqual(geoPoint.latitude, location.coordinate.latitude)
        XCTAssertEqual(geoPoint.longitude, location.coordinate.longitude)
    }
    #endif

    func testGeoPointEncoding() {
        let point = GeoPoint(latitude: 10, longitude: 20)

        do {
            let encoded = try ParseEncoder().encode(point)
            let decoded = try JSONDecoder().decode(GeoPoint.self, from: encoded)
            XCTAssertEqual(point, decoded)
        } catch {
            XCTFail("Should have encoded/decoded")
        }
    }

    // swiftlint:disable:next function_body_length
    func testGeoUtilityDistance() {
        let d2R = Double.pi / 180.0
        var pointA = GeoPoint()
        var pointB = GeoPoint()

        // Zero
        XCTAssertEqual(pointA.distanceInRadians(pointB), 0.0,
                       accuracy: 0.00001, "Origin points with non-zero distance.")
        XCTAssertEqual(pointB.distanceInRadians(pointA), 0.0,
                       accuracy: 0.00001, "Origin points with non-zero distance.")

        // Wrap Long
        pointA.longitude = 179.0
        pointB.longitude = -179.0
        XCTAssertEqual(pointA.distanceInRadians(pointB), 2.0 * d2R,
                       accuracy: 0.00001, "Long wrap angular distance error.")
        XCTAssertEqual(pointB.distanceInRadians(pointA), 2.0 * d2R,
                       accuracy: 0.00001, "Long wrap angular distance error.")

        // North South Lat
        pointA.latitude = 89.0
        pointA.longitude = 0.0
        pointB.latitude = -89.0
        pointB.longitude = 0.0
        XCTAssertEqual(pointA.distanceInRadians(pointB), 178.0 * d2R,
                       accuracy: 0.00001, "NS pole wrap error.")
        XCTAssertEqual(pointB.distanceInRadians(pointA), 178.0 * d2R,
                       accuracy: 0.00001, "NS pole wrap error.")

        // Long wrap Lat
        pointA.latitude = 89.0
        pointA.longitude = 0.0
        pointB.latitude = -89.0
        pointB.longitude = 179.9999
        XCTAssertEqual(pointA.distanceInRadians(pointB), 180.0 * d2R,
                       accuracy: 0.00001, "Lat wrap error.")
        XCTAssertEqual(pointB.distanceInRadians(pointA), 180.0 * d2R,
                       accuracy: 0.00001, "Lat wrap error.")

        pointA.latitude = 79.0
        pointA.longitude = 90.0
        pointB.latitude = -79.0
        pointB.longitude = -90
        XCTAssertEqual(pointA.distanceInRadians(pointB), 180.0 * d2R,
                       accuracy: 0.00001, "Lat long wrap error.")
        XCTAssertEqual(pointB.distanceInRadians(pointA), 180.0 * d2R,
                       accuracy: 0.00001, "Lat long wrap error.")

        // Wrap near pole - somewhat ill conditioned case due to pole proximity
        pointA.latitude = 85.0
        pointA.longitude = 90.0
        pointB.latitude = 85.0
        pointB.longitude = -90
        XCTAssertEqual(pointA.distanceInRadians(pointB), 10.0 * d2R,
                       accuracy: 0.00001, "Pole proximity fail")
        XCTAssertEqual(pointB.distanceInRadians(pointA), 10.0 * d2R,
                       accuracy: 0.00001, "Pole proximity fail")

        // Reference cities
        // Sydney Australia
        pointA.latitude = -34.0
        pointA.longitude = 151.0

        // Buenos Aires
        pointB.latitude = -34.5
        pointB.longitude = -58.35

        XCTAssertEqual(pointA.distanceInRadians(pointB), 1.85,
                       accuracy: 0.01, "Sydney to Buenos Aires Fail")
        XCTAssertEqual(pointB.distanceInRadians(pointA), 1.85,
                       accuracy: 0.01, "Sydney to Buenos Aires Fail")

        // [SAC]  38.52  -121.50  Sacramento,CA
        let sacramento = GeoPoint(latitude: 38.52, longitude: -121.50)

        // [HNL]  21.35  -157.93  Honolulu Int,HI
        let honolulu = GeoPoint(latitude: 21.35, longitude: -157.93)

        // [51Q]  37.75  -122.68  San Francisco,CA
        let sanfran = GeoPoint(latitude: 37.75, longitude: -122.68)

        // Vorkuta 67.509619,64.085999
        let vorkuta = GeoPoint(latitude: 67.509619, longitude: 64.085999)

        // London
        let london = GeoPoint(latitude: 51.501904, longitude: -0.115356)

        // Northampton
        let northhampton = GeoPoint(latitude: 52.241256, longitude: -0.895386)

        // Powell St BART station
        let powell = GeoPoint(latitude: 37.78507, longitude: -122.407007)

        // Apple store
        let astore = GeoPoint(latitude: 37.785809, longitude: -122.406363)

        // Self
        XCTAssertEqual(honolulu.distanceInKilometers(honolulu), 0.0,
                       accuracy: 0.00001, "Self distance")

        // Sac to HNL
        XCTAssertEqual(sacramento.distanceInKilometers(honolulu), 3964.8,
                       accuracy: 10.0, "SAC to HNL")
        XCTAssertEqual(sacramento.distanceInMiles(honolulu), 2463.6,
                       accuracy: 10.0, "SAC to HNL")

        // Semi-local
        XCTAssertEqual(london.distanceInKilometers(northhampton), 98.0,
                       accuracy: 1.0, "London Northhampton")
        XCTAssertEqual(london.distanceInMiles(northhampton), 61.2,
                       accuracy: 1.0, "London Northhampton")

        XCTAssertEqual(sacramento.distanceInKilometers(sanfran), 134.5,
                       accuracy: 2.0, "Sacramento San Fran")
        XCTAssertEqual(sacramento.distanceInMiles(sanfran), 84.8,
                       accuracy: 2.0, "Sacramento San Fran")

        // Very local
        XCTAssertEqual(powell.distanceInKilometers(astore), 0.1,
                       accuracy: 0.05, "Powell station and Apple store")

        // Far (for error tolerances's sake)
        XCTAssertEqual(sacramento.distanceInKilometers(vorkuta), 8303.8,
                       accuracy: 100.0, "Sacramento to Vorkuta")
        XCTAssertEqual(sacramento.distanceInMiles(vorkuta), 5159.7,
                       accuracy: 100.0, "Sacramento to Vorkuta")
    }

    func testDebugGeoPoint() {
        let point = GeoPoint(latitude: 10, longitude: 20)
        XCTAssertTrue(point.debugDescription.contains("10"))
        XCTAssertTrue(point.debugDescription.contains("20"))
    }
}
#endif
