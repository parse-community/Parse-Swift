//
//  ParseInstallationCombineTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/30/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if !os(Linux)

import Foundation
import XCTest
import Combine
@testable import ParseSwift

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
class ParseInstallationCombineTests: XCTestCase { // swiftlint:disable:this type_body_length

    struct User: ParseUser {

        //: Those are required for Object
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?

        // provided by User
        var username: String?
        var email: String?
        var password: String?
        var authData: [String: [String: String]?]?

        // Your custom keys
        var customKey: String?
    }

    struct LoginSignupResponse: ParseUser {

        var objectId: String?
        var createdAt: Date?
        var sessionToken: String
        var updatedAt: Date?
        var ACL: ParseACL?

        // provided by User
        var username: String?
        var email: String?
        var password: String?
        var authData: [String: [String: String]?]?

        // Your custom keys
        var customKey: String?

        init() {
            self.createdAt = Date()
            self.updatedAt = Date()
            self.objectId = "yarr"
            self.ACL = nil
            self.customKey = "blah"
            self.sessionToken = "myToken"
            self.username = "hello10"
            self.email = "hello@parse.com"
        }
    }

    struct Installation: ParseInstallation {
        var installationId: String?
        var deviceType: String?
        var deviceToken: String?
        var badge: Int?
        var timeZone: String?
        var channels: [String]?
        var appName: String?
        var appIdentifier: String?
        var appVersion: String?
        var parseVersion: String?
        var localeIdentifier: String?
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var customKey: String?
    }

    let testInstallationObjectId = "yarr"

    let loginUserName = "hello10"
    let loginPassword = "world"

    override func setUpWithError() throws {
        super.setUp()
        guard let url = URL(string: "http://localhost:1337/1") else {
            XCTFail("Should create valid URL")
            return
        }
        ParseSwift.initialize(applicationId: "applicationId",
                              clientKey: "clientKey",
                              masterKey: "masterKey",
                              serverURL: url,
                              testing: true)
        login()
    }

    override func tearDownWithError() throws {
        super.tearDown()
        MockURLProtocol.removeAll()
        #if !os(Linux)
        try KeychainStore.shared.deleteAll()
        #endif
        try ParseStorage.shared.deleteAll()
    }

    func login() {
        let loginResponse = LoginSignupResponse()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoder().encode(loginResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        do {
            _ = try User.login(username: loginUserName, password: loginPassword)

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func update() {
        var installation = Installation()
        installation.objectId = testInstallationObjectId
        installation.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        installation.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        installation.ACL = nil

        var installationOnServer = installation
        installationOnServer.updatedAt = Date()

        let encoded: Data!
        do {
            encoded = try installationOnServer.getEncoder().encode(installationOnServer, skipKeys: .none)
            //Get dates in correct format from ParseDecoding strategy
            installationOnServer = try installationOnServer.getDecoder().decode(Installation.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }
        let expectation1 = XCTestExpectation(description: "Update installation1")
        DispatchQueue.main.async {
            do {
                let saved = try installation.save()
                guard let savedUpdatedAt = saved.updatedAt else {
                        XCTFail("Should unwrap dates")
                        expectation1.fulfill()
                        return
                }
                guard let originalUpdatedAt = installation.updatedAt else {
                        XCTFail("Should unwrap dates")
                        expectation1.fulfill()
                        return
                }
                XCTAssertGreaterThan(savedUpdatedAt, originalUpdatedAt)
                XCTAssertNil(saved.ACL)
            } catch {
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testFetch() {
        update()
        MockURLProtocol.removeAll()

        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Update installation1")
        DispatchQueue.main.async {
            guard let installation = Installation.current,
                let savedObjectId = installation.objectId else {
                    XCTFail("Should unwrap")
                    expectation1.fulfill()
                    return
            }
            XCTAssertEqual(savedObjectId, self.testInstallationObjectId)

            var serverResponse = installation
            serverResponse.updatedAt = installation.updatedAt?.addingTimeInterval(+300)
            serverResponse.customKey = "newValue"

            MockURLProtocol.mockRequests { _ in
                do {
                    let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                    return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
                } catch {
                    return nil
                }
            }

            let publisher = installation.fetchPublisher()
                .sink(receiveCompletion: { result in

                    if case let .failure(error) = result {
                        XCTFail(error.localizedDescription)
                    }
                    expectation1.fulfill()

            }, receiveValue: { fetched in

                XCTAssert(fetched.hasSameObjectId(as: serverResponse))
                XCTAssertEqual(Installation.current?.customKey, serverResponse.customKey)
            })
            publisher.store(in: &subscriptions)
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testSave() {
        update()
        MockURLProtocol.removeAll()

        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Update installation1")
        DispatchQueue.main.async {
            guard var installation = Installation.current,
                let savedObjectId = installation.objectId else {
                    XCTFail("Should unwrap")
                    expectation1.fulfill()
                    return
            }
            installation.customKey = "newValue"
            XCTAssertEqual(savedObjectId, self.testInstallationObjectId)

            var serverResponse = installation
            serverResponse.updatedAt = installation.updatedAt?.addingTimeInterval(+300)

            MockURLProtocol.mockRequests { _ in
                do {
                    let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                    return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
                } catch {
                    return nil
                }
            }

            let publisher = installation.savePublisher()
                .sink(receiveCompletion: { result in

                    if case let .failure(error) = result {
                        XCTFail(error.localizedDescription)
                    }
                    expectation1.fulfill()

            }, receiveValue: { fetched in

                XCTAssert(fetched.hasSameObjectId(as: serverResponse))
                XCTAssertEqual(Installation.current?.customKey, serverResponse.customKey)
            })
            publisher.store(in: &subscriptions)
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testDelete() {
        update()
        MockURLProtocol.removeAll()

        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Update installation1")
        DispatchQueue.main.async {
            guard let installation = Installation.current,
                let savedObjectId = installation.objectId else {
                    XCTFail("Should unwrap")
                    expectation1.fulfill()
                    return
            }
            XCTAssertEqual(savedObjectId, self.testInstallationObjectId)

            var serverResponse = installation
            serverResponse.updatedAt = installation.updatedAt?.addingTimeInterval(+300)
            serverResponse.customKey = "newValue"

            MockURLProtocol.mockRequests { _ in
                do {
                    let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                    return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
                } catch {
                    return nil
                }
            }

            let publisher = installation.deletePublisher()
                .sink(receiveCompletion: { result in

                    if case let .failure(error) = result {
                        XCTFail(error.localizedDescription)
                    }
                    expectation1.fulfill()

            }, receiveValue: { _ in

            })
            publisher.store(in: &subscriptions)
        }
        wait(for: [expectation1], timeout: 20.0)
    }
}

#endif
