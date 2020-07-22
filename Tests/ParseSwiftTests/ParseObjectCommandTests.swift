//
//  ParseObjectCommandTests.swift
//  ParseSwiftTests
//
//  Created by Corey Baker on 7/19/20.
//  Copyright © 2020 Parse. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class ParseObjectCommandTests: XCTestCase {

    struct GameScore: ParseSwift.ObjectType {
        //: Those are required for Object
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ACL?

        //: Your own properties
        var score: Int

        //: a custom initializer
        init(score: Int) {
            self.score = score
        }
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
        var score = GameScore(score: 10)
        let className = score.className
        let objectId = "yarr"
        score.objectId = objectId
        do {
            let command = try score.fetchCommand()
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
        var score = GameScore(score: 10)
        let objectId = "yarr"
        score.objectId = objectId

        var scoreOnServer = score
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = Date()
        scoreOnServer.ACL = nil

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try scoreOnServer.getEncoderWithoutSkippingKeys().encode(scoreOnServer)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        do {
            let fetched = try score.fetch()
            XCTAssertNotNil(fetched)
            XCTAssertNotNil(fetched.createdAt)
            XCTAssertNotNil(fetched.updatedAt)
            XCTAssertNil(fetched.ACL)
        } catch {
            XCTFail(error.localizedDescription)
        }

        do {
            let fetched = try score.fetch(options: [.useMasterKey])
            XCTAssertNotNil(fetched)
            XCTAssertNotNil(fetched.createdAt)
            XCTAssertNotNil(fetched.updatedAt)
            XCTAssertNil(fetched.ACL)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testSaveCommand() {
        var score = GameScore(score: 10)
        let className = score.className
        let objectId = "yarr"
        score.objectId = objectId

        let command = score.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/classes/\(className)/\(objectId)")
        XCTAssertEqual(command.method, API.Method.PUT)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.body)
        XCTAssertNotNil(command.data)
    }

    func testSave() {
        var score = GameScore(score: 10)
        let objectId = "yarr"
        score.objectId = objectId

        var scoreOnServer = score
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = Date()
        scoreOnServer.ACL = nil

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try scoreOnServer.getEncoderWithoutSkippingKeys().encode(scoreOnServer)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
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
