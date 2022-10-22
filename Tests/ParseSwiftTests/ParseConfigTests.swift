//
//  ParseConfigTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/22/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class ParseConfigTests: XCTestCase { // swiftlint:disable:this type_body_length

    struct Config: ParseConfig {
        var welcomeMessage: String?
        var winningNumber: Int?
    }

    struct User: ParseUser {

        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

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
        var originalData: Data?

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

    func testUpdateKeyChainIfNeeded() throws {
        userLogin()
        let config = Config()
        XCTAssertNil(Config.current)

        Config.updateKeychainIfNeeded(config, deleting: true)
        XCTAssertNil(Config.current)
    }

    func testDeleteFromKeychainOnLogout() throws {
        userLogin()
        var config = Config()
        config.welcomeMessage = "Hello"
        XCTAssertNil(Config.current)

        Config.updateKeychainIfNeeded(config)
        XCTAssertNotNil(Config.current)
        XCTAssertEqual(config.welcomeMessage, Config.current?.welcomeMessage)

        let logoutResponse = NoBody()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(logoutResponse)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        try User.logout()
        XCTAssertNil(Config.current)
    }

    func testFetchCommand() throws {
        var config = Config()
        config.welcomeMessage = "Hello"
        let command = config.fetchCommand()
        XCTAssertEqual(command.path.urlComponent, "/config")
        XCTAssertEqual(command.method, API.Method.GET)
        XCTAssertNil(command.body)
    }

    func testDebugString() {
        var config = Config()
        config.welcomeMessage = "Hello"
        let expected = "{\"welcomeMessage\":\"Hello\"}"
        XCTAssertEqual(config.debugDescription, expected)
    }

    func testDescription() {
        var config = Config()
        config.welcomeMessage = "Hello"
        let expected = "{\"welcomeMessage\":\"Hello\"}"
        XCTAssertEqual(config.description, expected)
    }

    func testFetch() {
        userLogin()
        let config = Config()

        var configOnServer = config
        configOnServer.welcomeMessage = "Hello"
        let serverResponse = ConfigFetchResponse(params: configOnServer)
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }
        do {
            let fetched = try config.fetch()
            XCTAssertEqual(fetched.welcomeMessage, configOnServer.welcomeMessage)
            XCTAssertEqual(Config.current?.welcomeMessage, configOnServer.welcomeMessage)

            #if !os(Linux) && !os(Android) && !os(Windows)
            //Should be updated in Keychain
            guard let keychainConfig: CurrentConfigContainer<Config>
                = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentConfig) else {
                    XCTFail("Should get object from Keychain")
                return
            }
            XCTAssertEqual(keychainConfig.currentConfig?.welcomeMessage, configOnServer.welcomeMessage)
            #endif

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testFetchAsync() {
        userLogin()
        let config = Config()

        var configOnServer = config
        configOnServer.welcomeMessage = "Hello"
        let serverResponse = ConfigFetchResponse(params: configOnServer)
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let expectation = XCTestExpectation(description: "Config save")
        config.fetch { result in
            switch result {

            case .success(let fetched):
                XCTAssertEqual(fetched.welcomeMessage, configOnServer.welcomeMessage)
                XCTAssertEqual(Config.current?.welcomeMessage, configOnServer.welcomeMessage)

                #if !os(Linux) && !os(Android) && !os(Windows)
                //Should be updated in Keychain
                guard let keychainConfig: CurrentConfigContainer<Config>
                    = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentConfig) else {
                        XCTFail("Should get object from Keychain")
                    expectation.fulfill()
                    return
                }
                XCTAssertEqual(keychainConfig.currentConfig?.welcomeMessage, configOnServer.welcomeMessage)
                #endif

            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }

    func testUpdateCommand() throws {
        var config = Config()
        config.welcomeMessage = "Hello"
        let command = config.updateCommand()
        XCTAssertEqual(command.path.urlComponent, "/config")
        XCTAssertEqual(command.method, API.Method.PUT)
        XCTAssertNotNil(command.body)
    }

    func testSave() {
        userLogin()
        var config = Config()
        config.welcomeMessage = "Hello"

        let serverResponse = BooleanResponse(result: true)
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }
        do {
            let saved = try config.save()
            XCTAssertTrue(saved)
            XCTAssertEqual(Config.current?.welcomeMessage, config.welcomeMessage)

            #if !os(Linux) && !os(Android) && !os(Windows)
            //Should be updated in Keychain
            guard let keychainConfig: CurrentConfigContainer<Config>
                = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentConfig) else {
                    XCTFail("Should get object from Keychain")
                return
            }
            XCTAssertEqual(keychainConfig.currentConfig?.welcomeMessage, config.welcomeMessage)
            #endif
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testSaveAsync() {
        userLogin()
        var config = Config()
        config.welcomeMessage = "Hello"

        let serverResponse = BooleanResponse(result: true)
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let expectation = XCTestExpectation(description: "Config save")
        config.save { result in
            switch result {

            case .success(let saved):
                XCTAssertTrue(saved)
                XCTAssertEqual(Config.current?.welcomeMessage, config.welcomeMessage)

                #if !os(Linux) && !os(Android) && !os(Windows)
                //Should be updated in Keychain
                guard let keychainConfig: CurrentConfigContainer<Config>
                    = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentConfig) else {
                        XCTFail("Should get object from Keychain")
                    expectation.fulfill()
                    return
                }
                XCTAssertEqual(keychainConfig.currentConfig?.welcomeMessage, config.welcomeMessage)
                #endif

            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }
}
