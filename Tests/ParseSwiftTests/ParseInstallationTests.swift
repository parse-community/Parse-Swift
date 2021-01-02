//
//  ParseInstallationTests.swift
//  ParseSwiftTests
//
//  Created by Corey Baker on 9/7/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import XCTest
@testable import ParseSwift

class ParseInstallationTests: XCTestCase { // swiftlint:disable:this type_body_length

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
        userLogin()
    }

    override func tearDown() {
        super.tearDown()
        MockURLProtocol.removeAll()
        try? KeychainStore.shared.deleteAll()
        try? ParseStorage.shared.deleteAll()
    }

    func userLogin() {
        let loginResponse = LoginSignupResponse()
        let loginUserName = "hello10"
        let loginPassword = "world"

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
            MockURLProtocol.removeAll()
        } catch {
            XCTFail("Should login")
        }
    }

    func testNewInstallationIdentifierIsLowercase() {
        let expectation1 = XCTestExpectation(description: "Update installation1")
        DispatchQueue.main.async {
            guard let installationIdFromContainer
                = Installation.currentInstallationContainer.installationId else {
                XCTFail("Should have retreived installationId from container")
                    expectation1.fulfill()
                return
            }

            XCTAssertEqual(installationIdFromContainer, installationIdFromContainer.lowercased())

            guard let installationIdFromCurrent = Installation.current?.installationId else {
                XCTFail("Should have retreived installationId from container")
                expectation1.fulfill()
                return
            }

            XCTAssertEqual(installationIdFromCurrent, installationIdFromCurrent.lowercased())
            XCTAssertEqual(installationIdFromContainer, installationIdFromCurrent)
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testInstallationMutableValuesCanBeChangedInMemory() {
        let expectation1 = XCTestExpectation(description: "Update installation1")
        DispatchQueue.main.async {
            guard let originalInstallation = Installation.current else {
                XCTFail("All of these Installation values should have unwraped")
                expectation1.fulfill()
                return
            }

            Installation.current?.customKey = "Changed"
            XCTAssertNotEqual(originalInstallation.customKey, Installation.current?.customKey)
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testInstallationCustomValuesNotSavedToKeychain() {
        Installation.current?.customKey = "Changed"
        Installation.saveCurrentContainerToKeychain()
        guard let keychainInstallation: CurrentInstallationContainer<Installation>
            = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation) else {
            return
        }
        XCTAssertNil(keychainInstallation.currentInstallation?.customKey)
    }

    func testInstallationImmutableFieldsCannotBeChangedInMemory() {
        let expectation1 = XCTestExpectation(description: "Update installation1")
        DispatchQueue.main.async {
            guard let originalInstallation = Installation.current,
                let originalInstallationId = originalInstallation.installationId,
                let originalDeviceType = originalInstallation.deviceType,
                let originalBadge = originalInstallation.badge,
                let originalTimeZone = originalInstallation.timeZone,
                let originalAppName = originalInstallation.appName,
                let originalAppIdentifier = originalInstallation.appIdentifier,
                let originalAppVersion = originalInstallation.appVersion,
                let originalParseVersion = originalInstallation.parseVersion,
                let originalLocaleIdentifier = originalInstallation.localeIdentifier
                else {
                    XCTFail("All of these Installation values should have unwraped")
                    expectation1.fulfill()
                return
            }

            Installation.current?.installationId = "changed"
            Installation.current?.deviceType = "changed"
            Installation.current?.badge = 500
            Installation.current?.timeZone = "changed"
            Installation.current?.appName = "changed"
            Installation.current?.appIdentifier = "changed"
            Installation.current?.appVersion = "changed"
            Installation.current?.parseVersion = "changed"
            Installation.current?.localeIdentifier = "changed"

            XCTAssertEqual(originalInstallationId, Installation.current?.installationId)
            XCTAssertEqual(originalDeviceType, Installation.current?.deviceType)
            XCTAssertEqual(originalBadge, Installation.current?.badge)
            XCTAssertEqual(originalTimeZone, Installation.current?.timeZone)
            XCTAssertEqual(originalAppName, Installation.current?.appName)
            XCTAssertEqual(originalAppIdentifier, Installation.current?.appIdentifier)
            XCTAssertEqual(originalAppVersion, Installation.current?.appVersion)
            XCTAssertEqual(originalParseVersion, Installation.current?.parseVersion)
            XCTAssertEqual(originalLocaleIdentifier, Installation.current?.localeIdentifier)
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    // swiftlint:disable:next function_body_length
    func testInstallationImmutableFieldsCannotBeChangedInKeychain() {
        let expectation1 = XCTestExpectation(description: "Update installation1")
        DispatchQueue.main.async {
            guard let originalInstallation = Installation.current,
                let originalInstallationId = originalInstallation.installationId,
                let originalDeviceType = originalInstallation.deviceType,
                let originalBadge = originalInstallation.badge,
                let originalTimeZone = originalInstallation.timeZone,
                let originalAppName = originalInstallation.appName,
                let originalAppIdentifier = originalInstallation.appIdentifier,
                let originalAppVersion = originalInstallation.appVersion,
                let originalParseVersion = originalInstallation.parseVersion,
                let originalLocaleIdentifier = originalInstallation.localeIdentifier
                else {
                    XCTFail("All of these Installation values should have unwraped")
                    expectation1.fulfill()
                return
            }

            Installation.current?.installationId = "changed"
            Installation.current?.deviceType = "changed"
            Installation.current?.badge = 500
            Installation.current?.timeZone = "changed"
            Installation.current?.appName = "changed"
            Installation.current?.appIdentifier = "changed"
            Installation.current?.appVersion = "changed"
            Installation.current?.parseVersion = "changed"
            Installation.current?.localeIdentifier = "changed"

            Installation.saveCurrentContainerToKeychain()

            guard let keychainInstallation: CurrentInstallationContainer<Installation>
                = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation) else {
                    expectation1.fulfill()
                return
            }
            XCTAssertEqual(originalInstallationId, keychainInstallation.currentInstallation?.installationId)
            XCTAssertEqual(originalDeviceType, keychainInstallation.currentInstallation?.deviceType)
            XCTAssertEqual(originalBadge, keychainInstallation.currentInstallation?.badge)
            XCTAssertEqual(originalTimeZone, keychainInstallation.currentInstallation?.timeZone)
            XCTAssertEqual(originalAppName, keychainInstallation.currentInstallation?.appName)
            XCTAssertEqual(originalAppIdentifier, keychainInstallation.currentInstallation?.appIdentifier)
            XCTAssertEqual(originalAppVersion, keychainInstallation.currentInstallation?.appVersion)
            XCTAssertEqual(originalParseVersion, keychainInstallation.currentInstallation?.parseVersion)
            XCTAssertEqual(originalLocaleIdentifier, keychainInstallation.currentInstallation?.localeIdentifier)
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testInstallationHasApplicationBadge() {
        let expectation1 = XCTestExpectation(description: "Update installation1")
        DispatchQueue.main.async {
        #if canImport(UIKit) && !os(watchOS)
            UIApplication.shared.applicationIconBadgeNumber = 10
            guard let installationBadge = Installation.current?.badge else {
                XCTFail("Should have retreived badge")
                expectation1.fulfill()
                return
            }
            XCTAssertEqual(installationBadge, 10)
        #elseif canImport(AppKit)
            NSApplication.shared.dockTile.badgeLabel = "10"
            guard let installationBadge = Installation.current?.badge else {
                XCTFail("Should have retreived badge")
                expectation1.fulfill()
                return
            }
            XCTAssertEqual(installationBadge, 10)
        #endif
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testUpdate() {
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

    func testUpdateToCurrentInstallation() {
        testUpdate()
        let expectation1 = XCTestExpectation(description: "Update installation1")
        DispatchQueue.main.async {
            guard let savedObjectId = Installation.current?.objectId else {
                    XCTFail("Should unwrap dates")
                expectation1.fulfill()
                    return
            }
            XCTAssertEqual(savedObjectId, self.testInstallationObjectId)
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    // swiftlint:disable:next function_body_length
    func updateAsync(installation: Installation, installationOnServer: Installation, callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Update installation1")
        installation.save(options: [], callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let saved):
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

                if callbackQueue != .main {
                    DispatchQueue.main.async {
                        guard let savedUpdatedAt = Installation.current?.updatedAt else {
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
                        XCTAssertNil(Installation.current?.ACL)
                        expectation1.fulfill()
                    }
                } else {
                    guard let savedUpdatedAt = Installation.current?.updatedAt else {
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
                    XCTAssertNil(Installation.current?.ACL)
                    expectation1.fulfill()
                }

            case .failure(let error):
                XCTFail(error.localizedDescription)
                expectation1.fulfill()
            }
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testUpdateAsyncMainQueue() {
        testUpdate()
        MockURLProtocol.removeAll()

        var installation = Installation()
        installation.objectId = testInstallationObjectId
        installation.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        installation.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        installation.ACL = nil

        var installationOnServer = installation
        installationOnServer.updatedAt = Date()
        let encoded: Data!
        do {
            let encodedOriginal = try ParseCoding.jsonEncoder().encode(installation)
            //Get dates in correct format from ParseDecoding strategy
            installation = try installation.getDecoder().decode(Installation.self, from: encodedOriginal)

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

        self.updateAsync(installation: installation, installationOnServer: installationOnServer, callbackQueue: .main)
    }

    func testFetchCommand() {
        var installation = Installation()
        let objectId = "yarr"
        installation.objectId = objectId
        do {
            let command = try installation.fetchCommand()
            XCTAssertNotNil(command)
            XCTAssertEqual(command.path.urlComponent, "/installations/\(objectId)")
            XCTAssertEqual(command.method, API.Method.GET)
            XCTAssertNil(command.params)
            XCTAssertNil(command.body)
        } catch {
            XCTFail(error.localizedDescription)
        }

        let installation2 = Installation()
        XCTAssertThrowsError(try installation2.fetchCommand())
    }

    func testFetchUpdatedCurrentInstallation() { // swiftlint:disable:this function_body_length
        testUpdate()
        MockURLProtocol.removeAll()

        let expectation1 = XCTestExpectation(description: "Update installation1")
        DispatchQueue.main.async {
            guard let installation = Installation.current,
                let savedObjectId = installation.objectId else {
                    XCTFail("Should unwrap")
                    expectation1.fulfill()
                    return
            }
            XCTAssertEqual(savedObjectId, self.testInstallationObjectId)

            var installationOnServer = installation
            installationOnServer.updatedAt = installation.updatedAt?.addingTimeInterval(+300)
            installationOnServer.customKey = "newValue"

            let encoded: Data!
            do {
                encoded = try installationOnServer.getEncoder().encode(installationOnServer, skipKeys: .none)
                //Get dates in correct format from ParseDecoding strategy
                installationOnServer = try installationOnServer.getDecoder().decode(Installation.self, from: encoded)
            } catch {
                XCTFail("Should encode/decode. Error \(error)")
                expectation1.fulfill()
                return
            }
            MockURLProtocol.mockRequests { _ in
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            }

            do {
                let fetched = try installation.fetch(options: [.useMasterKey])
                XCTAssert(fetched.hasSameObjectId(as: installationOnServer))
                guard let fetchedCreatedAt = fetched.createdAt,
                    let fetchedUpdatedAt = fetched.updatedAt else {
                        XCTFail("Should unwrap dates")
                        expectation1.fulfill()
                        return
                }
                guard let originalCreatedAt = installationOnServer.createdAt,
                    let originalUpdatedAt = installation.updatedAt,
                    let serverUpdatedAt = installationOnServer.updatedAt else {
                        XCTFail("Should unwrap dates")
                        expectation1.fulfill()
                        return
                }
                XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
                XCTAssertGreaterThan(fetchedUpdatedAt, originalUpdatedAt)
                XCTAssertEqual(fetchedUpdatedAt, serverUpdatedAt)
                XCTAssertEqual(Installation.current?.customKey, installationOnServer.customKey)

                //Should be updated in memory
                guard let updatedCurrentDate = Installation.current?.updatedAt else {
                    XCTFail("Should unwrap current date")
                    expectation1.fulfill()
                    return
                }
                XCTAssertEqual(updatedCurrentDate, serverUpdatedAt)

                //Shold be updated in Keychain
                guard let keychainInstallation: CurrentInstallationContainer<BaseParseInstallation>
                    = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation),
                    let keychainUpdatedCurrentDate = keychainInstallation.currentInstallation?.updatedAt else {
                        XCTFail("Should get object from Keychain")
                        expectation1.fulfill()
                    return
                }
                XCTAssertEqual(keychainUpdatedCurrentDate, serverUpdatedAt)

            } catch {
                XCTFail(error.localizedDescription)
            }

            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testFetchUpdatedCurrentInstallationAsync() { // swiftlint:disable:this function_body_length
        testUpdate()
        MockURLProtocol.removeAll()

        let expectation1 = XCTestExpectation(description: "Update installation1")
        DispatchQueue.main.async {
            guard let installation = Installation.current else {
                XCTFail("Should unwrap")
                expectation1.fulfill()
                return
            }

            var installationOnServer = installation
            installationOnServer.updatedAt = installation.updatedAt?.addingTimeInterval(+300)
            installationOnServer.customKey = "newValue"

            let encoded: Data!
            do {
                encoded = try installationOnServer.getEncoder().encode(installationOnServer, skipKeys: .none)
                //Get dates in correct format from ParseDecoding strategy
                installationOnServer = try installationOnServer.getDecoder().decode(Installation.self, from: encoded)
            } catch {
                XCTFail("Should encode/decode. Error \(error)")
                expectation1.fulfill()
                return
            }
            MockURLProtocol.mockRequests { _ in
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            }

            installation.fetch(options: [], callbackQueue: .main) { result in

                switch result {
                case .success(let fetched):
                    XCTAssert(fetched.hasSameObjectId(as: installationOnServer))
                    guard let fetchedCreatedAt = fetched.createdAt,
                        let fetchedUpdatedAt = fetched.updatedAt else {
                            XCTFail("Should unwrap dates")
                            expectation1.fulfill()
                            return
                    }
                    guard let originalCreatedAt = installationOnServer.createdAt,
                        let originalUpdatedAt = installation.updatedAt,
                        let serverUpdatedAt = installationOnServer.updatedAt else {
                            XCTFail("Should unwrap dates")
                            expectation1.fulfill()
                            return
                    }
                    XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
                    XCTAssertGreaterThan(fetchedUpdatedAt, originalUpdatedAt)
                    XCTAssertEqual(fetchedUpdatedAt, serverUpdatedAt)
                    XCTAssertEqual(Installation.current?.customKey, installationOnServer.customKey)

                    //Should be updated in memory
                    guard let updatedCurrentDate = Installation.current?.updatedAt else {
                        XCTFail("Should unwrap current date")
                        expectation1.fulfill()
                        return
                    }
                    XCTAssertEqual(updatedCurrentDate, serverUpdatedAt)

                    //Shold be updated in Keychain
                    guard let keychainInstallation: CurrentInstallationContainer<BaseParseInstallation>
                        = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation),
                        let keychainUpdatedCurrentDate = keychainInstallation.currentInstallation?.updatedAt else {
                            XCTFail("Should get object from Keychain")
                            expectation1.fulfill()
                        return
                    }
                    XCTAssertEqual(keychainUpdatedCurrentDate, serverUpdatedAt)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()
            }
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testDeleteCommand() {
        var installation = Installation()
        let objectId = "yarr"
        installation.objectId = objectId
        do {
            let command = try installation.deleteCommand()
            XCTAssertNotNil(command)
            XCTAssertEqual(command.path.urlComponent, "/installations/\(objectId)")
            XCTAssertEqual(command.method, API.Method.DELETE)
            XCTAssertNil(command.params)
            XCTAssertNil(command.body)
        } catch {
            XCTFail(error.localizedDescription)
        }

        let installation2 = Installation()
        XCTAssertThrowsError(try installation2.deleteCommand())
    }

    func testDelete() {
        testUpdate()
        let expectation1 = XCTestExpectation(description: "Delete installation1")
        DispatchQueue.main.async {
            guard let installation = Installation.current else {
                    XCTFail("Should unwrap dates")
                expectation1.fulfill()
                    return
            }

            do {
                try installation.delete(options: [])
            } catch {
                XCTFail(error.localizedDescription)
            }

            do {
                try installation.delete(options: [.useMasterKey])
            } catch {
                XCTFail(error.localizedDescription)
            }

            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testDeleteAsyncMainQueue() {
        testUpdate()
        MockURLProtocol.removeAll()

        let expectation1 = XCTestExpectation(description: "Delete installation1")
        DispatchQueue.main.async {
            guard let installation = Installation.current else {
                XCTFail("Should unwrap")
                expectation1.fulfill()
                return
            }

            var installationOnServer = installation
            installationOnServer.updatedAt = installation.updatedAt?.addingTimeInterval(+300)

            let encoded: Data!
            do {
                encoded = try installationOnServer.getEncoder().encode(installationOnServer, skipKeys: .none)
                //Get dates in correct format from ParseDecoding strategy
                installationOnServer = try installationOnServer.getDecoder().decode(Installation.self, from: encoded)
            } catch {
                XCTFail("Should encode/decode. Error \(error)")
                expectation1.fulfill()
                return
            }
            MockURLProtocol.mockRequests { _ in
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            }

            installation.delete { error in
                XCTAssertNil(error)
                expectation1.fulfill()
            }
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    // swiftlint:disable:next function_body_length
    func testFetchAll() {
        testUpdate()
        MockURLProtocol.removeAll()

        let expectation1 = XCTestExpectation(description: "Fetch installation1")

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

            do {
                let fetched = try [installation].fetchAll()
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

                        //Shold be updated in Keychain
                        guard let keychainInstallation: CurrentInstallationContainer<BaseParseInstallation>
                            = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation),
                            let keychainUpdatedCurrentDate = keychainInstallation.currentInstallation?.updatedAt else {
                                XCTFail("Should get object from Keychain")
                                expectation1.fulfill()
                            return
                        }
                        XCTAssertEqual(keychainUpdatedCurrentDate, serverUpdatedAt)
                    case .failure(let error):
                        XCTFail("Should have fetched: \(error.localizedDescription)")
                    }
                }
            } catch {
                XCTFail(error.localizedDescription)
            }

            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    // swiftlint:disable:next function_body_length
    func testFetchAllAsyncMainQueue() {
        testUpdate()
        MockURLProtocol.removeAll()

        let expectation1 = XCTestExpectation(description: "Fetch installation1")
        DispatchQueue.main.async {
            guard var installation = Installation.current else {
                XCTFail("Should unwrap")
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

            [installation].fetchAll { results in
                switch results {

                case .success(let fetched):
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

                            //Shold be updated in Keychain
                            guard let keychainInstallation: CurrentInstallationContainer<BaseParseInstallation>
                                = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation),
                                let keychainUpdatedCurrentDate = keychainInstallation
                                    .currentInstallation?.updatedAt else {
                                    XCTFail("Should get object from Keychain")
                                    expectation1.fulfill()
                                return
                            }
                            XCTAssertEqual(keychainUpdatedCurrentDate, serverUpdatedAt)
                        case .failure(let error):
                            XCTFail("Should have fetched: \(error.localizedDescription)")
                        }
                    }
                case .failure(let error):
                    XCTFail("Should have fetched: \(error.localizedDescription)")
                }
                expectation1.fulfill()
            }
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testSaveCommand() {
        let installation = Installation()
        let command = installation.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/installations")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.body)
    }

    func testUpdateCommand() {
        var installation = Installation()
        let objectId = "yarr"
        installation.objectId = objectId

        let command = installation.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/installations/\(objectId)")
        XCTAssertEqual(command.method, API.Method.PUT)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.body)
    }

    // swiftlint:disable:next function_body_length
    func testSaveAll() {
        testUpdate()
        MockURLProtocol.removeAll()

        let expectation1 = XCTestExpectation(description: "Fetch installation1")

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

            do {
                let saved = try [installation].saveAll()
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

                        //Shold be updated in Keychain
                        guard let keychainInstallation: CurrentInstallationContainer<BaseParseInstallation>
                            = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation),
                            let keychainUpdatedCurrentDate = keychainInstallation.currentInstallation?.updatedAt else {
                                XCTFail("Should get object from Keychain")
                                expectation1.fulfill()
                            return
                        }
                        XCTAssertEqual(keychainUpdatedCurrentDate, serverUpdatedAt)
                    case .failure(let error):
                        XCTFail("Should have fetched: \(error.localizedDescription)")
                    }
                }
            } catch {
                XCTFail(error.localizedDescription)
            }

            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    // swiftlint:disable:next function_body_length
    func testSaveAllAsyncMainQueue() {
        testUpdate()
        MockURLProtocol.removeAll()

        let expectation1 = XCTestExpectation(description: "Fetch installation1")
        DispatchQueue.main.async {
            guard var installation = Installation.current else {
                XCTFail("Should unwrap")
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

            [installation].saveAll { results in
                switch results {

                case .success(let saved):
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

                            //Shold be updated in Keychain
                            guard let keychainInstallation: CurrentInstallationContainer<BaseParseInstallation>
                                = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation),
                                let keychainUpdatedCurrentDate = keychainInstallation
                                    .currentInstallation?.updatedAt else {
                                    XCTFail("Should get object from Keychain")
                                    expectation1.fulfill()
                                return
                            }
                            XCTAssertEqual(keychainUpdatedCurrentDate, serverUpdatedAt)
                        case .failure(let error):
                            XCTFail("Should have fetched: \(error.localizedDescription)")
                        }
                    }
                case .failure(let error):
                    XCTFail("Should have fetched: \(error.localizedDescription)")
                }
                expectation1.fulfill()
            }
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testDeleteAll() {
        testUpdate()
        MockURLProtocol.removeAll()

        let expectation1 = XCTestExpectation(description: "Delete installation1")

        DispatchQueue.main.async {
            guard let installation = Installation.current else {
                    XCTFail("Should unwrap dates")
                expectation1.fulfill()
                    return
            }

            let error: ParseError? = nil
            let installationOnServer = [error]

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

            do {
                let deleted = try [installation].deleteAll()
                deleted.forEach {
                    if let error = $0 {
                        XCTFail("Should have deleted: \(error.localizedDescription)")
                    }
                }
            } catch {
                XCTFail(error.localizedDescription)
            }

            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testDeleteAllAsyncMainQueue() {
        testUpdate()
        MockURLProtocol.removeAll()

        let expectation1 = XCTestExpectation(description: "Delete installation1")
        DispatchQueue.main.async {
            guard let installation = Installation.current else {
                XCTFail("Should unwrap")
                expectation1.fulfill()
                return
            }

            let error: ParseError? = nil
            let installationOnServer = [error]

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

            [installation].deleteAll { results in
                switch results {

                case .success(let deleted):
                    deleted.forEach {
                        if let error = $0 {
                            XCTFail("Should have deleted: \(error.localizedDescription)")
                        }
                    }
                case .failure(let error):
                    XCTFail("Should have deleted: \(error.localizedDescription)")
                }
                expectation1.fulfill()
            }
        }
        wait(for: [expectation1], timeout: 20.0)
    }
}
// swiftlint:disable:this file_length
