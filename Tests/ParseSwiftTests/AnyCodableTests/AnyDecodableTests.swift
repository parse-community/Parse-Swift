import XCTest
@testable import ParseSwift

class AnyDecodableTests: XCTestCase {
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
        do {
            let decoder = JSONDecoder()
            let dictionary = try decoder.decode([String: AnyDecodable].self, from: json)
            XCTAssertEqual(dictionary["boolean"]?.value as? Bool, true)
            XCTAssertEqual(dictionary["integer"]?.value as? Int, 1)
            guard let doubleValue = dictionary["double"]?.value as? Double else {
                XCTFail("Should unrap data as Double")
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
    static var allTests = [
        ("testJSONDecoding", testJSONDecoding)
    ]
}
