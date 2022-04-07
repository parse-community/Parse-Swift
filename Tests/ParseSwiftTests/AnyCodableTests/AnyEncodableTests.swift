import XCTest
@testable import ParseSwift

// Test has objective-c
#if !os(Linux) && !os(Android) && !os(Windows)
class AnyEncodableTests: XCTestCase {

    struct SomeEncodable: Encodable {
        var string: String
        var int: Int
        var bool: Bool
        var hasUnderscore: String

        // swiftlint:disable:next nesting
        enum CodingKeys: String, CodingKey {
            case string
            case int
            case bool
            case hasUnderscore = "has_underscore"
        }
    }

    func testJSONEncoding() {

        let someEncodable = AnyEncodable(SomeEncodable(string: "String",
                                                       int: 100,
                                                       bool: true,
                                                       hasUnderscore: "another string"))

        let dictionary: [String: AnyEncodable] = [
            "boolean": true,
            "integer": 42,
            "double": 3.14159265358979323846,
            "string": "string",
            "array": [1, 2, 3],
            "nested": [
                "a": "alpha",
                "b": "bravo",
                "c": "charlie"
            ],
            "someCodable": someEncodable,
            "null": nil
        ]

        do {
            let encoder = JSONEncoder()
            let json = try encoder.encode(dictionary)
            guard let encodedJSONObject =
                try JSONSerialization.jsonObject(with: json, options: []) as? NSDictionary else {
                    XCTFail("Should encode JSON object")
                    return
            }
            guard let expected = """
            {
                "boolean": 1,
                "integer": 42,
                "double": 3.14159265358979323846,
                "string": "string",
                "array": [1, 2, 3],
                "nested": {
                    "a": "alpha",
                    "b": "bravo",
                    "c": "charlie"
                },
                "someCodable": {
                    "string": "String",
                    "int": 100,
                    "bool": true,
                    "has_underscore": "another string"
                },
                "null": null
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
            XCTFail(error.localizedDescription)
        }
    }

    func testEncodeNSNumber() throws {
        let dictionary: [String: NSNumber] = [
            "boolean": true,
            "char": -127,
            "int": -32767,
            "short": -32767,
            "long": -2147483647,
            "longlong": -9223372036854775807,
            "uchar": 255,
            "uint": 65535,
            "ushort": 65535,
            "ulong": 4294967295,
            "ulonglong": 18446744073709615,
            "double": 3.141592653589793
        ]

        let encoder = JSONEncoder()

        let json = try encoder.encode(AnyEncodable(dictionary))
        guard let encodedJSONObject = try JSONSerialization.jsonObject(with: json, options: []) as? NSDictionary else {
            XCTFail("Should have unwrapped")
            return
        }

        let expected = """
        {
            "boolean": 1,
            "char": -127,
            "int": -32767,
            "short": -32767,
            "long": -2147483647,
            "longlong": -9223372036854775807,
            "uchar": 255,
            "uint": 65535,
            "ushort": 65535,
            "ulong": 4294967295,
            "ulonglong": 18446744073709615,
            "double": 3.141592653589793,
        }
        """.data(using: .utf8)!
        // swiftlint:disable:next line_length
        guard let expectedJSONObject = try JSONSerialization.jsonObject(with: expected, options: []) as? NSDictionary else {
            XCTFail("Should have unwrapped")
            return
        }

        XCTAssertEqual(encodedJSONObject, expectedJSONObject)
        XCTAssert(encodedJSONObject["boolean"] is Bool)

        XCTAssert(encodedJSONObject["char"] is Int8)
        XCTAssert(encodedJSONObject["int"] is Int16)
        XCTAssert(encodedJSONObject["short"] is Int32)
        XCTAssert(encodedJSONObject["long"] is Int32)
        XCTAssert(encodedJSONObject["longlong"] is Int64)

        XCTAssert(encodedJSONObject["uchar"] is UInt8)
        XCTAssert(encodedJSONObject["uint"] is UInt16)
        XCTAssert(encodedJSONObject["ushort"] is UInt32)
        XCTAssert(encodedJSONObject["ulong"] is UInt32)
        XCTAssert(encodedJSONObject["ulonglong"] is UInt64)

        XCTAssert(encodedJSONObject["double"] is Double)
    }

    func testStringInterpolationEncoding() throws {
        let dictionary: [String: AnyEncodable] = [
            "boolean": "\(true)",
            "integer": "\(42)",
            "double": "\(3.141592653589793)",
            "string": "\("string")",
            "array": "\([1, 2, 3])"
        ]

        let encoder = JSONEncoder()

        let json = try encoder.encode(dictionary)
        guard let encodedJSONObject = try JSONSerialization.jsonObject(with: json, options: []) as? NSDictionary else {
            XCTFail("Should have unwrapped")
            return
        }

        let expected = """
        {
            "boolean": "true",
            "integer": "42",
            "double": "3.141592653589793",
            "string": "string",
            "array": "[1, 2, 3]",
        }
        """.data(using: .utf8)!
        // swiftlint:disable:next line_length
        guard let expectedJSONObject = try JSONSerialization.jsonObject(with: expected, options: []) as? NSDictionary else {
            XCTFail("Should have unwrapped")
            return
        }

        XCTAssertEqual(encodedJSONObject, expectedJSONObject)
    }
}
#endif
