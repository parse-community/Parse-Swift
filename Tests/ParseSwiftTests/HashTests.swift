//
//  HashTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 12/22/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class HashTests: XCTestCase {
    func testMD5SimpleHash() {
        XCTAssertEqual("5eb63bbbe01eeed093cb22bb8f5acdc3", ParseHash.md5HashFromString("hello world"))
    }

    func testMD5HashFromUnicode() {
        XCTAssertEqual("9c853e20bb12ff256734a992dd224f17", ParseHash.md5HashFromString("foo א"))
    }
}
