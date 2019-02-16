import XCTest
@testable import ParseSwiftTests

XCTMain([
    testCase(ParseSwiftTests.allTests),
    testCase(AnyCodableTests.allTests)
])
