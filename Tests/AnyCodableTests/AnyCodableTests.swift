import XCTest
@testable import ParseSwift

class AnyCodableTests: XCTestCase {
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
            let dictionary = try decoder.decode([String: AnyCodable].self, from: json)
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
            XCTAssertNoThrow(try decoder.decode([String: AnyCodable].self, from: json))
        }
    }
    func testJSONEncoding() {
        let dictionary: [String: AnyCodable] = [
            "boolean": true,
            "integer": 1,
            "double": 3.14159265358979323846,
            "string": "string",
            "array": [1, 2, 3],
            "nested": [
                "a": "alpha",
                "b": "bravo",
                "c": "charlie"
            ]
        ]
        let encoder = JSONEncoder()
        do {
            let json = try encoder.encode(dictionary)
            guard let encodedJSONObject =
                try JSONSerialization.jsonObject(with: json, options: []) as? NSDictionary else {
                    throw ParseSwiftTestError.cantUnwrap
            }
            guard let expected = """
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
            """.data(using: .utf8) else {
                throw ParseSwiftTestError.cantUnwrap
            }
            guard let expectedJSONObject =
                try JSONSerialization.jsonObject(with: expected, options: []) as? NSDictionary else {
                throw ParseSwiftTestError.cantUnwrap
            }
            XCTAssertEqual(encodedJSONObject, expectedJSONObject)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    static var allTests = [
        ("testJSONDecoding", testJSONDecoding),
        ("testJSONEncoding", testJSONEncoding)
    ]
}
