//
//  ParseObjectCommandTests.swift
//  ParseSwiftTests
//
//  Created by Corey Baker on 7/19/20.
//  Copyright © 2020 Parse Community. All rights reserved.
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
        let score = GameScore(score: 10)
        let className = score.className

        let command = score.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/classes/\(className)")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.body)
        XCTAssertNotNil(command.data)
    }

    func testUpdateCommand() {
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
        let score = GameScore(score: 10)

        var scoreOnServer = score
        scoreOnServer.objectId = "yarr"
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
            let saved = try score.save()
            XCTAssertNotNil(saved)
            XCTAssertNotNil(saved.createdAt)
            XCTAssertNotNil(saved.updatedAt)
            XCTAssertNil(saved.ACL)
        } catch {
            XCTFail(error.localizedDescription)
        }

        do {
            let saved = try score.save(options: [.useMasterKey])
            XCTAssertNotNil(saved)
            XCTAssertNotNil(saved.createdAt)
            XCTAssertNotNil(saved.updatedAt)
            XCTAssertNil(saved.ACL)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testUpdate() { // swiftlint:disable:this function_body_length
        var score = GameScore(score: 10)
        score.objectId = "yarr"
        score.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        score.ACL = nil

        var scoreOnServer = score
        scoreOnServer.updatedAt = Date()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try scoreOnServer.getEncoderWithoutSkippingKeys().encode(scoreOnServer)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        do {
            let saved = try score.save()
            XCTAssertNotNil(saved)
            guard let savedCreatedAt = saved.createdAt,
                let savedUpdatedAt = saved.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            guard let originalCreatedAt = score.createdAt,
                let originalUpdatedAt = score.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            XCTAssertEqual(savedCreatedAt, originalCreatedAt)
            XCTAssertGreaterThan(savedUpdatedAt, originalUpdatedAt)
            XCTAssertNil(saved.ACL)
        } catch {
            XCTFail(error.localizedDescription)
        }

        do {
            let saved = try score.save(options: [.useMasterKey])
            XCTAssertNotNil(saved)
            guard let savedCreatedAt = saved.createdAt,
                let savedUpdatedAt = saved.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            guard let originalCreatedAt = score.createdAt,
                let originalUpdatedAt = score.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            XCTAssertEqual(savedCreatedAt, originalCreatedAt)
            XCTAssertGreaterThan(savedUpdatedAt, originalUpdatedAt)
            XCTAssertNil(saved.ACL)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
