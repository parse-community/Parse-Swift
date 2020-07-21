//
//  ParseUserCommandTests.swift
//  ParseSwiftTests
//
//  Created by Corey Baker on 7/21/20.
//  Copyright © 2020 Parse. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class ParseUserCommandTests: XCTestCase {

    struct User: ParseSwift.UserType {
        //: Those are required for Object
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ACL?

        // provided by User
        var username: String?
        var email: String?
        var password: String?

        // Your custom keys
        var customKey: String?
    }

    let parseDateEncodingStrategy: ParseEncoder.DateEncodingStrategy = .custom({ (date, enc) in
        var container = enc.container(keyedBy: DateEncodingKeys.self)
        try container.encode("Date", forKey: .type)
        let dateString = dateFormatter.string(from: date)
        try container.encode(dateString, forKey: .iso)
    })

    override func setUp() {
        super.setUp()
        guard let url = URL(string: "http://localhost:1337/1") else {
            XCTFail("Should create valid URL")
            return
        }
        ParseSwift.initialize(applicationId: "applicationId",
                              clientKey: "clientKey",
                              masterKey: "masterKey",
                              serverURL: url)
    }

    override func tearDown() {
        super.tearDown()
        MockURLProtocol.removeAll()
    }

    func testFetchCommand() {
        var user = User()
        let className = user.className
        let objectId = "yarr"
        user.objectId = objectId
        do {
            let command = try user.fetchCommand()
            XCTAssertNotNil(command)
            XCTAssertEqual(command.path.urlComponent, "/classes/\(className)/\(objectId)")
            XCTAssertEqual(command.method, API.Method.GET)
            XCTAssertNil(command.params)
            XCTAssertNil(command.body)
            XCTAssertNil(command.data)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testFetch() {
        var user = User()
        let objectId = "yarr"
        user.objectId = objectId

        var scoreOnServer = user
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = Date()
        scoreOnServer.ACL = nil

        MockURLProtocol.mockRequests { response in
            do {
                let encoded = try scoreOnServer.getEncoderWithoutSkippingKeys().encode(scoreOnServer)
                let response = MockURLResponse(data: encoded, statusCode: 0, delay: 0.0)
                return response
            } catch {
                return nil
            }
        }
        do {
            let fetched = try user.fetch()
            XCTAssertNotNil(fetched)
            XCTAssertNotNil(fetched.createdAt)
            XCTAssertNotNil(fetched.updatedAt)
            XCTAssertNil(fetched.ACL)
        } catch {
            XCTFail(error.localizedDescription)
        }

        do {
            let fetched = try user.fetch(options: [.useMasterKey])
            XCTAssertNotNil(fetched)
            XCTAssertNotNil(fetched.createdAt)
            XCTAssertNotNil(fetched.updatedAt)
            XCTAssertNil(fetched.ACL)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testSaveCommand() {
        var user = User()
        let className = user.className
        let objectId = "yarr"
        user.objectId = objectId

        let command = user.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/classes/\(className)/\(objectId)")
        XCTAssertEqual(command.method, API.Method.PUT)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.body)
        XCTAssertNotNil(command.data)
    }

    func testSave() {
        var user = User()
        let objectId = "yarr"
        user.objectId = objectId

        var scoreOnServer = user
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = Date()
        scoreOnServer.ACL = nil

        MockURLProtocol.mockRequests { response in
            do {
                let encoded = try scoreOnServer.getEncoderWithoutSkippingKeys().encode(scoreOnServer)
                let response = MockURLResponse(data: encoded, statusCode: 0, delay: 0.0)
                return response
            } catch {
                return nil
            }
        }
        do {
            let saved = try scoreOnServer.save()
            XCTAssertNotNil(saved)
            XCTAssertNotNil(saved.createdAt)
            XCTAssertNotNil(saved.updatedAt)
            XCTAssertNil(saved.ACL)
        } catch {
            XCTFail(error.localizedDescription)
        }

        do {
            let saved = try scoreOnServer.save(options: [.useMasterKey])
            XCTAssertNotNil(saved)
            XCTAssertNotNil(saved.createdAt)
            XCTAssertNotNil(saved.updatedAt)
            XCTAssertNil(saved.ACL)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
