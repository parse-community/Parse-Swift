import XCTest
@testable import ParseSwift

class AnyEncodableTests: XCTestCase {
    func testJSONEncoding() {
        let dictionary: [String: AnyEncodable] = [
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
                    XCTFail("Should encode JSON object")
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
                XCTFail("Should unrap serialized json object")
                return
            }
            XCTAssertEqual(encodedJSONObject, expectedJSONObject)
        } catch {
            XCTAssertNoThrow(try encoder.encode(dictionary), error.localizedDescription)
        }
    }
    static var allTests = [
        ("testJSONEncoding", testJSONEncoding)
    ]
}
