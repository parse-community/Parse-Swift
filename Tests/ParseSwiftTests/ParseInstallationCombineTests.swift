//
//  ParseInstallationCombineTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/30/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if canImport(Combine)

import Foundation
import XCTest
import Combine
@testable import ParseSwift

@available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
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
            let date = Date()
            self.createdAt = date
            self.updatedAt = date
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
        try super.setUpWithError()
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
        try super.tearDownWithError()
        MockURLProtocol.removeAll()
        #if !os(Linux) && !os(Android)
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

    func testFetchAll() {
        update()
        MockURLProtocol.removeAll()
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Fetch")

        DispatchQueue.main.async {
            guard var installation = Installation.current else {
                    XCTFail("Should unwrap dates")
                expectation1.fulfill()
                    return
            }

            installation.updatedAt = installation.updatedAt?.addingTimeInterval(+300)
            installation.customKey = "newValue"
            let installationOnServer = QueryResponse<Installation>(results: [installation], count: 1)

            let encoded: Data!
            do {
                encoded = try ParseCoding.jsonEncoder().encode(installationOnServer)
                //Get dates in correct format from ParseDecoding strategy
                let encoded1 = try ParseCoding.jsonEncoder().encode(installation)
                installation = try installation.getDecoder().decode(Installation.self, from: encoded1)
            } catch {
                XCTFail("Should encode/decode. Error \(error)")
                expectation1.fulfill()
                return
            }
            MockURLProtocol.mockRequests { _ in
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            }

            let publisher = [installation].fetchAllPublisher()
                .sink(receiveCompletion: { result in

                    if case let .failure(error) = result {
                        XCTFail(error.localizedDescription)
                    }
                    expectation1.fulfill()

            }, receiveValue: { fetched in

                fetched.forEach {
                    switch $0 {
                    case .success(let fetched):
                        XCTAssert(fetched.hasSameObjectId(as: installation))
                        guard let fetchedCreatedAt = fetched.createdAt,
                            let fetchedUpdatedAt = fetched.updatedAt else {
                                XCTFail("Should unwrap dates")
                                expectation1.fulfill()
                                return
                        }
                        guard let originalCreatedAt = installation.createdAt,
                            let originalUpdatedAt = installation.updatedAt,
                            let serverUpdatedAt = installation.updatedAt else {
                                XCTFail("Should unwrap dates")
                                expectation1.fulfill()
                                return
                        }
                        XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
                        XCTAssertEqual(fetchedUpdatedAt, originalUpdatedAt)
                        XCTAssertEqual(fetchedUpdatedAt, serverUpdatedAt)
                        XCTAssertEqual(Installation.current?.customKey, installation.customKey)

                        //Should be updated in memory
                        guard let updatedCurrentDate = Installation.current?.updatedAt else {
                            XCTFail("Should unwrap current date")
                            expectation1.fulfill()
                            return
                        }
                        XCTAssertEqual(updatedCurrentDate, serverUpdatedAt)

                        #if !os(Linux) && !os(Android)
                        //Should be updated in Keychain
                        guard let keychainInstallation: CurrentInstallationContainer<BaseParseInstallation>
                            = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation),
                            let keychainUpdatedCurrentDate = keychainInstallation.currentInstallation?.updatedAt else {
                                XCTFail("Should get object from Keychain")
                                expectation1.fulfill()
                            return
                        }
                        XCTAssertEqual(keychainUpdatedCurrentDate, serverUpdatedAt)
                        #endif
                    case .failure(let error):
                        XCTFail("Should have fetched: \(error.localizedDescription)")
                    }
                }
            })
            publisher.store(in: &subscriptions)
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testSaveAll() {
        update()
        MockURLProtocol.removeAll()
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")

        DispatchQueue.main.async {
            guard var installation = Installation.current else {
                    XCTFail("Should unwrap dates")
                expectation1.fulfill()
                    return
            }

            installation.updatedAt = installation.updatedAt?.addingTimeInterval(+300)
            installation.customKey = "newValue"
            let installationOnServer = [BatchResponseItem<Installation>(success: installation, error: nil)]

            let encoded: Data!
            do {
                encoded = try ParseCoding.jsonEncoder().encode(installationOnServer)
                //Get dates in correct format from ParseDecoding strategy
                let encoded1 = try ParseCoding.jsonEncoder().encode(installation)
                installation = try installation.getDecoder().decode(Installation.self, from: encoded1)
            } catch {
                XCTFail("Should encode/decode. Error \(error)")
                expectation1.fulfill()
                return
            }
            MockURLProtocol.mockRequests { _ in
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            }

            let publisher = [installation].saveAllPublisher()
                .sink(receiveCompletion: { result in

                    if case let .failure(error) = result {
                        XCTFail(error.localizedDescription)
                    }
                    expectation1.fulfill()

            }, receiveValue: { saved in

                saved.forEach {
                    switch $0 {
                    case .success(let saved):
                        XCTAssert(saved.hasSameObjectId(as: installation))
                        guard let savedCreatedAt = saved.createdAt,
                            let savedUpdatedAt = saved.updatedAt else {
                                XCTFail("Should unwrap dates")
                                expectation1.fulfill()
                                return
                        }
                        guard let originalCreatedAt = installation.createdAt,
                            let originalUpdatedAt = installation.updatedAt,
                            let serverUpdatedAt = installation.updatedAt else {
                                XCTFail("Should unwrap dates")
                                expectation1.fulfill()
                                return
                        }
                        XCTAssertEqual(savedCreatedAt, originalCreatedAt)
                        XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
                        XCTAssertEqual(savedUpdatedAt, serverUpdatedAt)
                        XCTAssertEqual(Installation.current?.customKey, installation.customKey)

                        //Should be updated in memory
                        guard let updatedCurrentDate = Installation.current?.updatedAt else {
                            XCTFail("Should unwrap current date")
                            expectation1.fulfill()
                            return
                        }
                        XCTAssertEqual(updatedCurrentDate, serverUpdatedAt)

                        #if !os(Linux) && !os(Android)
                        //Should be updated in Keychain
                        guard let keychainInstallation: CurrentInstallationContainer<BaseParseInstallation>
                            = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation),
                            let keychainUpdatedCurrentDate = keychainInstallation.currentInstallation?.updatedAt else {
                                XCTFail("Should get object from Keychain")
                                expectation1.fulfill()
                            return
                        }
                        XCTAssertEqual(keychainUpdatedCurrentDate, serverUpdatedAt)
                        #endif
                    case .failure(let error):
                        XCTFail("Should have fetched: \(error.localizedDescription)")
                    }
                }
            })
            publisher.store(in: &subscriptions)
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testDeleteAll() {
        update()
        MockURLProtocol.removeAll()
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")

        DispatchQueue.main.async {
            guard let installation = Installation.current else {
                    XCTFail("Should unwrap dates")
                expectation1.fulfill()
                    return
            }

            let installationOnServer = [BatchResponseItem<NoBody>(success: NoBody(), error: nil)]

            let encoded: Data!
            do {
                encoded = try ParseCoding.jsonEncoder().encode(installationOnServer)
            } catch {
                XCTFail("Should encode/decode. Error \(error)")
                expectation1.fulfill()
                return
            }
            MockURLProtocol.mockRequests { _ in
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            }

            let publisher = [installation].deleteAllPublisher()
                .sink(receiveCompletion: { result in

                    if case let .failure(error) = result {
                        XCTFail(error.localizedDescription)
                    }
                    expectation1.fulfill()

            }, receiveValue: { deleted in
                deleted.forEach {
                    if case let .failure(error) = $0 {
                        XCTFail("Should have deleted: \(error.localizedDescription)")
                    }
                }
            })
            publisher.store(in: &subscriptions)
        }
        wait(for: [expectation1], timeout: 20.0)
    }
}

#endif
