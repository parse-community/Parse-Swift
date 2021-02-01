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
    }

    override func tearDownWithError() throws {
        super.tearDown()
        MockURLProtocol.removeAll()
        #if !os(Linux)
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
        XCTAssertNil(command.params)
        XCTAssertNil(command.body)
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

            #if !os(Linux)
            //Should be updated in Keychain
            guard let keychainConfig: CurrentConfigContainer<Config>
                = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentConfig) else {
                    XCTFail("Should get object from Keychain")
                return
            }
            XCTAssertEqual(keychainConfig.currentConfig?.welcomeMessage, configOnServer.welcomeMessage)
            #endif

            XCTAssertEqual(Config.current?.welcomeMessage, configOnServer.welcomeMessage)
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

                #if !os(Linux)
                //Should be updated in Keychain
                guard let keychainConfig: CurrentConfigContainer<Config>
                    = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentConfig) else {
                        XCTFail("Should get object from Keychain")
                    expectation.fulfill()
                    return
                }
                XCTAssertEqual(keychainConfig.currentConfig?.welcomeMessage, configOnServer.welcomeMessage)
                #endif

                XCTAssertEqual(Config.current?.welcomeMessage, configOnServer.welcomeMessage)
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
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.body)
    }

    func testSave() {
        userLogin()
        var config = Config()
        config.welcomeMessage = "Hello"

        let serverResponse = ConfigUpdateResponse(result: true)
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

            #if !os(Linux)
            //Should be updated in Keychain
            guard let keychainConfig: CurrentConfigContainer<Config>
                = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentConfig) else {
                    XCTFail("Should get object from Keychain")
                return
            }
            XCTAssertEqual(keychainConfig.currentConfig?.welcomeMessage, config.welcomeMessage)
            #endif

            XCTAssertEqual(Config.current?.welcomeMessage, config.welcomeMessage)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testSaveAsync() {
        userLogin()
        var config = Config()
        config.welcomeMessage = "Hello"

        let serverResponse = ConfigUpdateResponse(result: true)
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

                #if !os(Linux)
                //Should be updated in Keychain
                guard let keychainConfig: CurrentConfigContainer<Config>
                    = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentConfig) else {
                        XCTFail("Should get object from Keychain")
                    expectation.fulfill()
                    return
                }
                XCTAssertEqual(keychainConfig.currentConfig?.welcomeMessage, config.welcomeMessage)
                #endif

                XCTAssertEqual(Config.current?.welcomeMessage, config.welcomeMessage)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }
}
