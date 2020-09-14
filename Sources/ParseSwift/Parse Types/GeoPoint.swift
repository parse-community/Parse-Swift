import Foundation

/**
 `PFGeoPoint` may be used to embed a latitude / longitude point as the value for a key in a `PFObject`.
 It could be used to perform queries in a geospatial manner using `PFQuery.-whereKey:nearGeoPoint:`.
 Currently, instances of `PFObject` may only have one key associated with a `PFGeoPoint` type.
*/
public struct GeoPoint: Codable {
    private let __type: String = "GeoPoint" // swiftlint:disable:this identifier_name
    private let earthRadiusMiles = 3958.8
    private let earthRadiusKilometers = 6371.0

    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
    }

    /**
    Latitude of point in degrees. Valid range is from `-90.0` to `90.0`.
    */
    public let latitude: Double

    /**
    Longitude of point in degrees. Valid range is from `-180.0` to `180.0`.
    */
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        assert(latitude > -180, "latitude should be > -180")
        assert(latitude < 180, "latitude should be > -180")
        assert(latitude > -90, "latitude should be > -90")
        assert(latitude < 90, "latitude should be > 90")
        self.latitude = latitude
        self.longitude = longitude
    }

    /**
     Get distance in radians from this point to specified point.
     
     - parameters point: `PFGeoPoint` that represents the location of other point.
     - returns: Distance in radians between the receiver and `point`.
    */
    public func distanceInRadians(_ point: GeoPoint) -> Double {
        let d2r: Double = .pi / 180.0 // radian conversion factor
        let lat1rad = self.latitude * d2r
        let long1rad = self.longitude * d2r
        let lat2rad = point.latitude * d2r
        let long2rad = point.longitude * d2r
        let deltaLat = lat1rad - lat2rad
        let deltaLong = long1rad - long2rad
        let sinDeltaLatDiv2 = sin(deltaLat / 2.0)
        let sinDeltaLongDiv2 = sin(deltaLong / 2.0)
        // Square of half the straight line chord distance between both points. [0.0, 1.0]
        var partialDistance = sinDeltaLatDiv2 * sinDeltaLatDiv2 +
            cos(lat1rad) * cos(lat2rad) * sinDeltaLongDiv2 * sinDeltaLongDiv2
        partialDistance = fmin(1.0, partialDistance)
        return 2.0 * asin(sqrt(partialDistance))
    }

    /**
     Get distance in miles from this point to specified point.
     
     - parameters point: `PFGeoPoint` that represents the location of other point.
     - returns: Distance in miles between the receiver and `point`.
    */
    public func distanceInMiles(_ point: GeoPoint) -> Double {
        return distanceInRadians(point) * earthRadiusMiles
    }

    /**
     Get distance in kilometers from this point to specified point.
     - parameters point: `PFGeoPoint` that represents the location of other point.
     - returns: Distance in kilometers between the receiver and `point`.
    */
    public func distancesInKilometers(_ point: GeoPoint) -> Double {
        return distanceInRadians(point) * earthRadiusKilometers
    }
}

extension GeoPoint {
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        longitude = try values.decode(Double.self, forKey: .longitude)
        latitude = try values.decode(Double.self, forKey: .latitude)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(latitude, forKey: .latitude)
    }
}
