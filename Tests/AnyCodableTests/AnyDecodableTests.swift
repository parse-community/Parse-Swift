import XCTest
@testable import ParseSwift

class AnyDecodableTests: XCTestCase {
    func testJSONDecoding() {
        let json = """
        {
            "boolean": true,
            "integer": 1,
            "double": 3.14159265358979323846,
            "string": "string",
            "array": [1, 2, 3],
            "nested": {
                "a": "alpha",
                "b": "bravo",
                "c": "charlie"
            }
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        do {
            let dictionary = try decoder.decode([String: AnyDecodable].self, from: json)
            XCTAssertEqual(dictionary["boolean"]?.value as? Bool, true)
            XCTAssertEqual(dictionary["integer"]?.value as? Int, 1)
            guard let doubleValue = dictionary["double"]?.value as? Double else {
                throw ParseSwiftTestError.cantUnwrap
            }
            XCTAssertEqual(doubleValue, 3.14159265358979323846, accuracy: 0.001)
            XCTAssertEqual(dictionary["string"]?.value as? String, "string")
            XCTAssertEqual(dictionary["array"]?.value as? [Int], [1, 2, 3])
            XCTAssertEqual(dictionary["nested"]?.value as? [String: String],
                           ["a": "alpha", "b": "bravo", "c": "charlie"])
        } catch {
            XCTAssertNoThrow(try decoder.decode([String: AnyDecodable].self, from: json))
        }
    }
    static var allTests = [
        ("testJSONDecoding", testJSONDecoding)
    ]
}
