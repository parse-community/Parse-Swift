import Foundation

public struct GeoPoint: Codable {
    private let __type: String = "GeoPoint"
    public let latitude: Double
    public let longitude: Double
    public init(latitude: Double, longitude: Double) {
        assert(latitude > -180, "latitude should be > -180")
        assert(latitude < 180, "latitude should be > -180")
        assert(latitude > -90, "latitude should be > -90")
        assert(latitude < 90, "latitude should be > 90")
        self.latitude = latitude
        self.longitude = longitude
    }
}
