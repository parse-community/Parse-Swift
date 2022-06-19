import Foundation
#if canImport(CoreLocation)
import CoreLocation
#endif

/**
  `ParseGeoPoint` is used to embed a latitude / longitude point as the value for a key in a `ParseObject`.
   It could be used to perform queries in a geospatial manner using `ParseQuery.whereKey:nearGeoPoint:`.

 - warning:Currently, instances of `ParseObject` may only have one key associated with a `ParseGeoPoint` type.
*/
public struct ParseGeoPoint: ParseTypeable, Hashable {
    private let __type: String = "GeoPoint" // swiftlint:disable:this identifier_name
    static let earthRadiusMiles = 3958.8
    static let earthRadiusKilometers = 6371.0

    enum CodingKeys: String, CodingKey {
        case __type, latitude, longitude // swiftlint:disable:this identifier_name
    }

    /**
      Latitude of point in degrees. Valid range is from `-90.0` to `90.0`.
    */
    public var latitude: Double

    /**
      Longitude of point in degrees. Valid range is from `-180.0` to `180.0`.
    */
    public var longitude: Double

    /**
     Create a `ParseGeoPoint` instance. Latitude and longitude are set to `0.0`.
     */
    public init() {
        latitude = 0.0
        longitude = 0.0
    }

    /**
      Create a new `ParseGeoPoint` instance with the specified latitude and longitude.
       - parameter latitude: Latitude of point in degrees.
       - parameter longitude: Longitude of point in degrees.
       - throws: An error of type `ParseError`.
     */
    public init(latitude: Double, longitude: Double) throws {
        self.latitude = latitude
        self.longitude = longitude
        try validate()
    }

    func validate() throws {
        if longitude < -180 {
            throw ParseError(code: .unknownError,
                             message: "longitude should be > -180")
        } else if longitude > 180 {
            throw ParseError(code: .unknownError,
                             message: "longitude should be < 180")
        } else if latitude < -90 {
            throw ParseError(code: .unknownError,
                             message: "latitude should be > -90")
        } else if latitude > 90 {
            throw ParseError(code: .unknownError,
                             message: "latitude should be < 90")
        }
    }

    /**
     Get distance in radians from this point to specified point.

     - parameter point: `ParseGeoPoint` that represents the location of other point.
     - returns: Distance in radians between the receiver and `point`.
    */
    public func distanceInRadians(_ point: ParseGeoPoint) -> Double {
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
     - parameter point: `ParseGeoPoint` that represents the location of other point.
     - returns: Distance in miles between the receiver and `point`.
    */
    public func distanceInMiles(_ point: ParseGeoPoint) -> Double {
        return distanceInRadians(point) * Self.earthRadiusMiles
    }

    /**
     Get distance in kilometers from this point to specified point.
     - parameter point: `ParseGeoPoint` that represents the location of other point.
     - returns: Distance in kilometers between the receiver and `point`.
    */
    public func distanceInKilometers(_ point: ParseGeoPoint) -> Double {
        return distanceInRadians(point) * Self.earthRadiusKilometers
    }
}

extension ParseGeoPoint {
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        longitude = try values.decode(Double.self, forKey: .longitude)
        latitude = try values.decode(Double.self, forKey: .latitude)
        try validate()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(__type, forKey: .__type)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(latitude, forKey: .latitude)
        try validate()
    }
}

#if canImport(CoreLocation)
// MARK: CoreLocation
public extension ParseGeoPoint {

    /**
     A `CLLocation` instance created from the current `ParseGeoPoint`.
     */
    var toCLLocation: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }

    /**
     A `CLLocationCoordinate2D` instance created from the current `ParseGeoPoint`.
     */
    var toCLLocationCoordinate2D: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /**
     Creates a new `ParseGeoPoint` instance for the given `CLLocation`, set to the location's coordinates.
     - parameter location: Instance of `CLLocation`, with set latitude and longitude.
     - throws: An error of `ParseError` type.
     */
    init(location: CLLocation) throws {
        self.longitude = location.coordinate.longitude
        self.latitude = location.coordinate.latitude
        try validate()
    }

    /**
     Creates a new `ParseGeoPoint` instance for the given `CLLocationCoordinate2D`, set to the location's coordinates.
     - parameter location: Instance of `CLLocationCoordinate2D`, with set latitude and longitude.
     - throws: An error of `ParseError` type.
     */
    init(coordinate: CLLocationCoordinate2D) throws {
        self.longitude = coordinate.longitude
        self.latitude = coordinate.latitude
        try validate()
    }

    /**
     A `CLLocation` instance created from the current `ParseGeoPoint`.
     - returns: Returns a `CLLocation`.
     */
    @available(*, deprecated, message: "Use the computed property instead by removing \"()\"")
    func toCLLocation(_ geoPoint: ParseGeoPoint? = nil) -> CLLocation {
        toCLLocation
    }

    /**
     A `CLLocationCoordinate2D` instance created from the current `ParseGeoPoint`.
     - returns: Returns a `CLLocationCoordinate2D`.
     */
    @available(*, deprecated, message: "Use the computed property instead by removing \"()\"")
    func toCLLocationCoordinate2D(_ geoPoint: ParseGeoPoint? = nil) -> CLLocationCoordinate2D {
        toCLLocationCoordinate2D
    }
}
#endif
