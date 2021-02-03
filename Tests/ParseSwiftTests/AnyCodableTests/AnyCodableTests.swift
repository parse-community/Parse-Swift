import XCTest
@testable import ParseSwift

class AnyCodableTests: XCTestCase {
    func testJSONDecoding() {
        guard let json = """
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
            XCTFail("Should unrap data as utf8")
            return
        }
        let decoder = JSONDecoder()
        do {
            let dictionary = try decoder.decode([String: AnyCodable].self, from: json)
            XCTAssertEqual(dictionary["boolean"]?.value as? Bool, true)
            XCTAssertEqual(dictionary["integer"]?.value as? Int, 1)
            guard let doubleValue = dictionary["double"]?.value as? Double else {
                XCTFail("Should unrap value as Double")
                return
            }
            XCTAssertEqual(doubleValue, 3.14159265358979323846, accuracy: 0.001)
            XCTAssertEqual(dictionary["string"]?.value as? String, "string")
            XCTAssertEqual(dictionary["array"]?.value as? [Int], [1, 2, 3])
            XCTAssertEqual(dictionary["nested"]?.value as? [String: String],
                           ["a": "alpha", "b": "bravo", "c": "charlie"])
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    //Test has objective-c
    #if !os(Linux)
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
        do {
            let encoder = JSONEncoder()
            let json = try encoder.encode(dictionary)
            guard let encodedJSONObject =
                try JSONSerialization.jsonObject(with: json, options: []) as? NSDictionary else {
                    XCTFail("Should unrap JSON serialized object")
                    return
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
                XCTFail("Should unrap data to utf8")
                return
            }
            guard let expectedJSONObject =
                try JSONSerialization.jsonObject(with: expected, options: []) as? NSDictionary else {
                XCTFail("Should unrap JSON serialized object")
                return
            }
            XCTAssertEqual(encodedJSONObject, expectedJSONObject)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    #endif
}
