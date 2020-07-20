//
//  APITests.swift
//  ParseSwiftTests
//
//  Created by Corey Baker on 7/19/20.
//  Copyright © 2020 Parse. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class APITests: XCTestCase {
    //var testStore: KeychainStore!
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        //_ = testStore.removeAllObjects()
    }

    func testNoRetryOn400() {
        var retryCount = 0
        MockURLProtocol.mockRequests(response: {_ in
            retryCount += 1
            let responseString = """
            {
                "error": "yarr",
                "code": 100500
            }
            """
            do {
                let response = try MockURLResponse(string: responseString, statusCode: 400, delay: 0.0)
                return response
            } catch {
                XCTFail(error.localizedDescription)
                return nil
            }
        })
        let test = API.Command<NoBody, NoBody>(method: .POST,
                                  path: .login,
                                  params: nil) { _ -> NoBody in
                                    return NoBody()
        }
        ParseSwift.initialize(applicationId: "applicationId",
                              clientKey: "clientKey",
                              masterKey: "masterKey",
                              serverURL: URL(string: "http://localhost:1337/1")!)
        //XCTAssertTrue(testStore.set(object: "yarr", forKey: "blah"), "Set should succeed")
    }
}
