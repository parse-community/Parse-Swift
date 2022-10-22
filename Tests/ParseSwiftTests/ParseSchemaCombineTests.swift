//
//  ParseSchemaCombineTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 5/29/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

#if canImport(Combine)

import Foundation
import XCTest
import Combine
@testable import ParseSwift

class ParseSchemaCombineTests: XCTestCase { // swiftlint:disable:this type_body_length
    struct GameScore: ParseObject, ParseQueryScorable {
        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var score: Double?
        var originalData: Data?

        //: Your own properties
        var points: Int
        var isCounts: Bool?

        //: a custom initializer
        init() {
            self.points = 5
        }
        init(points: Int) {
            self.points = points
        }
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        guard let url = URL(string: "http://localhost:1337/1") else {
            XCTFail("Should create valid URL")
            return
        }
        ParseSwift.initialize(applicationId: "applicationId",
                              clientKey: "clientKey",
                              primaryKey: "primaryKey",
                              serverURL: url,
                              testing: true)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        MockURLProtocol.removeAll()
        #if !os(Linux) && !os(Android) && !os(Windows)
        try KeychainStore.shared.deleteAll()
        #endif
        try ParseStorage.shared.deleteAll()
    }

    func createDummySchema() -> ParseSchema<GameScore> {
        ParseSchema<GameScore>()
            .addField("a",
                      type: .string,
                      options: ParseFieldOptions<String>(required: false, defauleValue: nil))
            .addField("b",
                      type: .number,
                      options: ParseFieldOptions<Int>(required: false, defauleValue: 2))
            .deleteField("c")
            .addIndex("hello", field: "world", index: "yolo")
    }

    func testCreate() throws {
        var subscriptions = Set<AnyCancellable>()
        let schema = createDummySchema()

        var serverResponse = schema
        serverResponse.indexes = schema.pendingIndexes
        serverResponse.pendingIndexes.removeAll()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Save schema")
        let publisher = schema.createPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { saved in

            XCTAssertEqual(saved.fields, serverResponse.fields)
            XCTAssertEqual(saved.indexes, serverResponse.indexes)
            XCTAssertEqual(saved.classLevelPermissions, serverResponse.classLevelPermissions)
            XCTAssertEqual(saved.className, serverResponse.className)
            XCTAssertTrue(saved.pendingIndexes.isEmpty)
        })
        publisher.store(in: &subscriptions)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testCreateError() throws {
        var subscriptions = Set<AnyCancellable>()
        let schema = createDummySchema()

        let parseError = ParseError(code: .invalidSchemaOperation,
                                    message: "Problem with schema")

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(parseError)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Create schema")
        let publisher = schema.createPublisher()
            .sink(receiveCompletion: { result in

                if case .finished = result {
                    XCTFail("Should have thrown ParseError")
                }
                expectation1.fulfill()

        }, receiveValue: { _ in
            XCTFail("Should have thrown ParseError")
            expectation1.fulfill()
        })
        publisher.store(in: &subscriptions)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testUpdate() throws {
        var subscriptions = Set<AnyCancellable>()
        let schema = createDummySchema()

        var serverResponse = schema
        serverResponse.indexes = schema.pendingIndexes
        serverResponse.pendingIndexes.removeAll()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Update schema")
        let publisher = schema.updatePublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { saved in

            XCTAssertEqual(saved.fields, serverResponse.fields)
            XCTAssertEqual(saved.indexes, serverResponse.indexes)
            XCTAssertEqual(saved.classLevelPermissions, serverResponse.classLevelPermissions)
            XCTAssertEqual(saved.className, serverResponse.className)
            XCTAssertTrue(saved.pendingIndexes.isEmpty)
        })
        publisher.store(in: &subscriptions)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testUpdateError() throws {
        var subscriptions = Set<AnyCancellable>()
        let schema = createDummySchema()

        let parseError = ParseError(code: .invalidSchemaOperation,
                                    message: "Problem with schema")

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(parseError)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Update schema")
        let publisher = schema.updatePublisher()
            .sink(receiveCompletion: { result in

                if case .finished = result {
                    XCTFail("Should have thrown ParseError")
                }
                expectation1.fulfill()

        }, receiveValue: { _ in
            XCTFail("Should have thrown ParseError")
            expectation1.fulfill()
        })
        publisher.store(in: &subscriptions)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testFetch() throws {
        var subscriptions = Set<AnyCancellable>()
        let schema = createDummySchema()

        var serverResponse = schema
        serverResponse.indexes = schema.pendingIndexes
        serverResponse.pendingIndexes.removeAll()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Fetch schema")
        let publisher = schema.fetchPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { saved in

            XCTAssertEqual(saved.fields, serverResponse.fields)
            XCTAssertEqual(saved.indexes, serverResponse.indexes)
            XCTAssertEqual(saved.classLevelPermissions, serverResponse.classLevelPermissions)
            XCTAssertEqual(saved.className, serverResponse.className)
            XCTAssertTrue(saved.pendingIndexes.isEmpty)
        })
        publisher.store(in: &subscriptions)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testFetchError() throws {
        var subscriptions = Set<AnyCancellable>()
        let schema = createDummySchema()

        let parseError = ParseError(code: .invalidSchemaOperation,
                                    message: "Problem with schema")

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(parseError)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Fetch schema")
        let publisher = schema.fetchPublisher()
            .sink(receiveCompletion: { result in

                if case .finished = result {
                    XCTFail("Should have thrown ParseError")
                }
                expectation1.fulfill()

        }, receiveValue: { _ in
            XCTFail("Should have thrown ParseError")
            expectation1.fulfill()
        })
        publisher.store(in: &subscriptions)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testPurge() throws {
        var subscriptions = Set<AnyCancellable>()
        let schema = createDummySchema()

        var serverResponse = schema
        serverResponse.indexes = schema.pendingIndexes
        serverResponse.pendingIndexes.removeAll()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Purge schema")
        let publisher = schema.purgePublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { _ in

        })
        publisher.store(in: &subscriptions)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testPurgeError() throws {
        var subscriptions = Set<AnyCancellable>()
        let schema = createDummySchema()

        let parseError = ParseError(code: .invalidSchemaOperation,
                                    message: "Problem with schema")

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(parseError)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Purge schema")
        let publisher = schema.purgePublisher()
            .sink(receiveCompletion: { result in

                if case .finished = result {
                    XCTFail("Should have thrown ParseError")
                }
                expectation1.fulfill()

        }, receiveValue: { _ in
            XCTFail("Should have thrown ParseError")
            expectation1.fulfill()
        })
        publisher.store(in: &subscriptions)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testDelete() throws {
        var subscriptions = Set<AnyCancellable>()
        let schema = createDummySchema()

        var serverResponse = schema
        serverResponse.indexes = schema.pendingIndexes
        serverResponse.pendingIndexes.removeAll()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Delete schema")
        let publisher = schema.deletePublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { _ in

        })
        publisher.store(in: &subscriptions)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testDeleteError() throws {
        var subscriptions = Set<AnyCancellable>()
        let schema = createDummySchema()

        let parseError = ParseError(code: .invalidSchemaOperation,
                                    message: "Problem with schema")

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(parseError)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Delete schema")
        let publisher = schema.deletePublisher()
            .sink(receiveCompletion: { result in

                if case .finished = result {
                    XCTFail("Should have thrown ParseError")
                }
                expectation1.fulfill()

        }, receiveValue: { _ in
            XCTFail("Should have thrown ParseError")
            expectation1.fulfill()
        })
        publisher.store(in: &subscriptions)
        wait(for: [expectation1], timeout: 20.0)
    }
}
#endif
