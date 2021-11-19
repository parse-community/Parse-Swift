//
//  ParseInstallationAsyncTests.swift
//  ParseInstallationAsyncTests
//
//  Created by Corey Baker on 8/6/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if swift(>=5.5) && canImport(_Concurrency) && !os(Linux) && !os(Android) && !os(Windows)
import Foundation
import XCTest
@testable import ParseSwift

class ParseInstallationAsyncTests: XCTestCase { // swiftlint:disable:this type_body_length

    struct User: ParseUser {

        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?

        // These are required by ParseUser
        var username: String?
        var email: String?
        var emailVerified: Bool?
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

        // These are required by ParseUser
        var username: String?
        var email: String?
        var emailVerified: Bool?
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
        #if !os(Linux) && !os(Android) && !os(Windows)
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

    func saveCurrentInstallation() throws {
        guard var installation = Installation.current else {
            XCTFail("Should unwrap")
            return
        }
        installation.objectId = testInstallationObjectId
        installation.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        installation.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        installation.ACL = nil

        var installationOnServer = installation

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

        do {
            guard let saved = try Installation.current?.save(),
                let newCurrentInstallation = Installation.current else {
                XCTFail("Should have a new current installation")
                return
            }
            XCTAssertTrue(saved.hasSameInstallationId(as: newCurrentInstallation))
            XCTAssertTrue(saved.hasSameObjectId(as: newCurrentInstallation))
            XCTAssertTrue(saved.hasSameObjectId(as: installationOnServer))
            XCTAssertTrue(saved.hasSameInstallationId(as: installationOnServer))
            XCTAssertNil(saved.ACL)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testFetch() async throws {
        try saveCurrentInstallation()
        MockURLProtocol.removeAll()

        guard let installation = Installation.current,
            let savedObjectId = installation.objectId else {
                XCTFail("Should unwrap")
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

        let fetched = try await installation.fetch()
        XCTAssert(fetched.hasSameObjectId(as: serverResponse))
        XCTAssert(fetched.hasSameInstallationId(as: serverResponse))
        XCTAssertEqual(Installation.current?.customKey, serverResponse.customKey)
    }

    func testSave() async throws {
        try saveCurrentInstallation()
        MockURLProtocol.removeAll()

        guard var installation = Installation.current,
            let savedObjectId = installation.objectId else {
                XCTFail("Should unwrap")
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

        let fetched = try await installation.save()
        XCTAssert(fetched.hasSameObjectId(as: serverResponse))
        XCTAssert(fetched.hasSameInstallationId(as: serverResponse))
        XCTAssertEqual(Installation.current?.customKey, serverResponse.customKey)
    }

    func testDelete() async throws {
        try saveCurrentInstallation()
        MockURLProtocol.removeAll()

        guard let installation = Installation.current,
            let savedObjectId = installation.objectId else {
                XCTFail("Should unwrap")
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

        _ = try await installation.delete()
        if let newInstallation = Installation.current {
            XCTAssertFalse(installation.hasSameInstallationId(as: newInstallation))
        }
    }

    func testFetchAll() async throws {
        try saveCurrentInstallation()
        MockURLProtocol.removeAll()

        guard var installation = Installation.current else {
            XCTFail("Should unwrap dates")
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
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let fetched = try await [installation].fetchAll()
        fetched.forEach {
            switch $0 {
            case .success(let fetched):
                XCTAssert(fetched.hasSameObjectId(as: installation))
                guard let fetchedCreatedAt = fetched.createdAt,
                    let fetchedUpdatedAt = fetched.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                guard let originalCreatedAt = installation.createdAt,
                    let originalUpdatedAt = installation.updatedAt,
                    let serverUpdatedAt = installation.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
                XCTAssertEqual(fetchedUpdatedAt, originalUpdatedAt)
                XCTAssertEqual(fetchedUpdatedAt, serverUpdatedAt)
                XCTAssertEqual(Installation.current?.customKey, installation.customKey)

                //Should be updated in memory
                guard let updatedCurrentDate = Installation.current?.updatedAt else {
                    XCTFail("Should unwrap current date")
                    return
                }
                XCTAssertEqual(updatedCurrentDate, serverUpdatedAt)

                #if !os(Linux) && !os(Android) && !os(Windows)
                //Should be updated in Keychain
                guard let keychainInstallation: CurrentInstallationContainer<BaseParseInstallation>
                    = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation),
                    let keychainUpdatedCurrentDate = keychainInstallation.currentInstallation?.updatedAt else {
                        XCTFail("Should get object from Keychain")
                    return
                }
                XCTAssertEqual(keychainUpdatedCurrentDate, serverUpdatedAt)
                #endif
            case .failure(let error):
                XCTFail("Should have fetched: \(error.localizedDescription)")
            }
        }
    }

    func testSaveAll() async throws {
        try saveCurrentInstallation()
        MockURLProtocol.removeAll()

        guard var installation = Installation.current else {
            XCTFail("Should unwrap dates")
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
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let saved = try await [installation].saveAll()
        saved.forEach {
            switch $0 {
            case .success(let saved):
                XCTAssert(saved.hasSameObjectId(as: installation))
                XCTAssert(saved.hasSameInstallationId(as: installation))
                guard let savedCreatedAt = saved.createdAt,
                    let savedUpdatedAt = saved.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                guard let originalCreatedAt = installation.createdAt,
                    let originalUpdatedAt = installation.updatedAt,
                    let serverUpdatedAt = installation.updatedAt else {
                        XCTFail("Should unwrap dates")
                        return
                }
                XCTAssertEqual(savedCreatedAt, originalCreatedAt)
                XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
                XCTAssertEqual(savedUpdatedAt, serverUpdatedAt)
                XCTAssertEqual(Installation.current?.customKey, installation.customKey)

                //Should be updated in memory
                guard let updatedCurrentDate = Installation.current?.updatedAt else {
                    XCTFail("Should unwrap current date")
                    return
                }
                XCTAssertEqual(updatedCurrentDate, serverUpdatedAt)

                #if !os(Linux) && !os(Android) && !os(Windows)
                //Should be updated in Keychain
                guard let keychainInstallation: CurrentInstallationContainer<BaseParseInstallation>
                    = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation),
                    let keychainUpdatedCurrentDate = keychainInstallation.currentInstallation?.updatedAt else {
                        XCTFail("Should get object from Keychain")
                    return
                }
                XCTAssertEqual(keychainUpdatedCurrentDate, serverUpdatedAt)
                #endif
            case .failure(let error):
                XCTFail("Should have fetched: \(error.localizedDescription)")
            }
        }
    }

    func testDeleteAll() async throws {
        try saveCurrentInstallation()
        MockURLProtocol.removeAll()

        guard let installation = Installation.current else {
            XCTFail("Should unwrap dates")
            return
        }

        let installationOnServer = [BatchResponseItem<NoBody>(success: NoBody(), error: nil)]

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(installationOnServer)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let deleted = try await [installation].deleteAll()
        deleted.forEach {
            if case let .failure(error) = $0 {
                XCTFail("Should have deleted: \(error.localizedDescription)")
            }
            if let newInstallation = Installation.current {
                XCTAssertFalse(installation.hasSameInstallationId(as: newInstallation))
            }
        }
    }
}
#endif
