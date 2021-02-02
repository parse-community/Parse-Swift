//
//  ParseUserCombineTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/29/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if canImport(Combine)

import Foundation
import XCTest
import Combine
@testable import ParseSwift

@available(macOS 10.15, iOS 13.0, macCatalyst 13.0, watchOS 6.0, tvOS 13.0, *)
class ParseUserCombineTests: XCTestCase { // swiftlint:disable:this type_body_length

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
    }

    override func tearDownWithError() throws {
        super.tearDown()
        MockURLProtocol.removeAll()
        #if !os(Linux)
        try KeychainStore.shared.deleteAll()
        #endif
        try ParseStorage.shared.deleteAll()
    }

    func testSignup() {
        let loginResponse = LoginSignupResponse()
        var subscriptions = Set<AnyCancellable>()
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoder().encode(loginResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Signup user1")
        let publisher = User.signupPublisher(username: loginUserName, password: loginUserName)
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { signedUp in
            XCTAssertNotNil(signedUp)
            XCTAssertNotNil(signedUp.createdAt)
            XCTAssertNotNil(signedUp.updatedAt)
            XCTAssertNotNil(signedUp.email)
            XCTAssertNotNil(signedUp.username)
            XCTAssertNil(signedUp.password)
            XCTAssertNotNil(signedUp.objectId)
            XCTAssertNotNil(signedUp.sessionToken)
            XCTAssertNotNil(signedUp.customKey)
            XCTAssertNil(signedUp.ACL)

            guard let userFromKeychain = BaseParseUser.current else {
                XCTFail("Couldn't get CurrentUser from Keychain")
                return
            }

            XCTAssertNotNil(userFromKeychain.createdAt)
            XCTAssertNotNil(userFromKeychain.updatedAt)
            XCTAssertNotNil(userFromKeychain.email)
            XCTAssertNotNil(userFromKeychain.username)
            XCTAssertNil(userFromKeychain.password)
            XCTAssertNotNil(userFromKeychain.objectId)
            XCTAssertNotNil(userFromKeychain.sessionToken)
            XCTAssertNil(userFromKeychain.ACL)
        })
        publisher.store(in: &subscriptions)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testLogin() {
        let loginResponse = LoginSignupResponse()
        var subscriptions = Set<AnyCancellable>()
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoder().encode(loginResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Login user1")
        let publisher = User.loginPublisher(username: loginUserName, password: loginUserName)
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { signedUp in
            XCTAssertNotNil(signedUp)
            XCTAssertNotNil(signedUp.createdAt)
            XCTAssertNotNil(signedUp.updatedAt)
            XCTAssertNotNil(signedUp.email)
            XCTAssertNotNil(signedUp.username)
            XCTAssertNil(signedUp.password)
            XCTAssertNotNil(signedUp.objectId)
            XCTAssertNotNil(signedUp.sessionToken)
            XCTAssertNotNil(signedUp.customKey)
            XCTAssertNil(signedUp.ACL)

            guard let userFromKeychain = BaseParseUser.current else {
                XCTFail("Couldn't get CurrentUser from Keychain")
                return
            }

            XCTAssertNotNil(userFromKeychain.createdAt)
            XCTAssertNotNil(userFromKeychain.updatedAt)
            XCTAssertNotNil(userFromKeychain.email)
            XCTAssertNotNil(userFromKeychain.username)
            XCTAssertNil(userFromKeychain.password)
            XCTAssertNotNil(userFromKeychain.objectId)
            XCTAssertNotNil(userFromKeychain.sessionToken)
            XCTAssertNil(userFromKeychain.ACL)
        })
        publisher.store(in: &subscriptions)
        wait(for: [expectation1], timeout: 20.0)
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

    func testBecome() {
        login()
        MockURLProtocol.removeAll()
        XCTAssertNotNil(User.current?.objectId)

        guard let user = User.current else {
            XCTFail("Should unwrap")
            return
        }

        var serverResponse = LoginSignupResponse()
        serverResponse.createdAt = User.current?.createdAt
        serverResponse.updatedAt = User.current?.updatedAt?.addingTimeInterval(+300)
        serverResponse.sessionToken = "newValue"
        serverResponse.username = "stop"

        var subscriptions = Set<AnyCancellable>()
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Become user1")
        let publisher = user.becomePublisher(sessionToken: serverResponse.sessionToken)
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { signedUp in
            XCTAssertNotNil(signedUp)
            XCTAssertNotNil(signedUp.createdAt)
            XCTAssertNotNil(signedUp.updatedAt)
            XCTAssertNotNil(signedUp.email)
            XCTAssertNotNil(signedUp.username)
            XCTAssertNil(signedUp.password)
            XCTAssertNotNil(signedUp.objectId)
            XCTAssertNotNil(signedUp.sessionToken)
            XCTAssertNotNil(signedUp.customKey)
            XCTAssertNil(signedUp.ACL)

            guard let userFromKeychain = BaseParseUser.current else {
                XCTFail("Couldn't get CurrentUser from Keychain")
                return
            }

            XCTAssertNotNil(userFromKeychain.createdAt)
            XCTAssertNotNil(userFromKeychain.updatedAt)
            XCTAssertNotNil(userFromKeychain.email)
            XCTAssertNotNil(userFromKeychain.username)
            XCTAssertNil(userFromKeychain.password)
            XCTAssertNotNil(userFromKeychain.objectId)
            XCTAssertNotNil(userFromKeychain.sessionToken)
            XCTAssertNil(userFromKeychain.ACL)
        })
        publisher.store(in: &subscriptions)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testLogout() {
        login()
        MockURLProtocol.removeAll()
        XCTAssertNotNil(User.current?.objectId)

        let serverResponse = NoBody()

        var subscriptions = Set<AnyCancellable>()
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Logout user1")
        let publisher = User.logoutPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { _ in
            if let userFromKeychain = BaseParseUser.current {
                XCTFail("\(userFromKeychain) wasn't deleted from Keychain during logout")
            }

            if let installationFromMemory: CurrentInstallationContainer<BaseParseInstallation>
                = try? ParseStorage.shared.get(valueFor: ParseStorage.Keys.currentInstallation) {
                XCTFail("\(installationFromMemory) wasn't deleted from memory during logout")
            }

            #if !os(Linux)
            if let installationFromKeychain: CurrentInstallationContainer<BaseParseInstallation>
                = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation) {
                XCTFail("\(installationFromKeychain) wasn't deleted from Keychain during logout")
            }
            #endif
        })
        publisher.store(in: &subscriptions)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testLogoutError() {
        login()
        MockURLProtocol.removeAll()
        XCTAssertNotNil(User.current?.objectId)

        let serverResponse = ParseError(code: .internalServer, message: "Object not found")

        var subscriptions = Set<AnyCancellable>()
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Logout user1")
        let publisher = User.logoutPublisher()
            .sink(receiveCompletion: { result in

                if case .finished = result {
                    XCTFail("Should have thrown ParseError")
                }

                if let userFromKeychain = BaseParseUser.current {
                    XCTFail("\(userFromKeychain) wasn't deleted from Keychain during logout")
                }

                if let installationFromMemory: CurrentInstallationContainer<BaseParseInstallation>
                    = try? ParseStorage.shared.get(valueFor: ParseStorage.Keys.currentInstallation) {
                    XCTFail("\(installationFromMemory) wasn't deleted from memory during logout")
                }

                #if !os(Linux)
                if let installationFromKeychain: CurrentInstallationContainer<BaseParseInstallation>
                    = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation) {
                    XCTFail("\(installationFromKeychain) wasn't deleted from Keychain during logout")
                }
                #endif
                expectation1.fulfill()

        }, receiveValue: { _ in
            XCTFail("Should have thrown ParseError")
        })
        publisher.store(in: &subscriptions)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testPasswordReset() {
        let serverResponse = NoBody()

        var subscriptions = Set<AnyCancellable>()
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Password user1")
        let publisher = User.passwordResetPublisher(email: "hello@parse.org")
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

    func testPasswordResetError() {
        let parseError = ParseError(code: .internalServer, message: "Object not found")

        var subscriptions = Set<AnyCancellable>()
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(parseError)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Password user1")
        let publisher = User.passwordResetPublisher(email: "hello@parse.org")
            .sink(receiveCompletion: { result in

                if case .finished = result {
                    XCTFail("Should have thrown ParseError")
                }
                expectation1.fulfill()

        }, receiveValue: { _ in
            XCTFail("Should have thrown ParseError")
        })
        publisher.store(in: &subscriptions)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testVerificationEmail() {
        let serverResponse = NoBody()

        var subscriptions = Set<AnyCancellable>()
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Verification user1")
        let publisher = User.verificationEmailPublisher(email: "hello@parse.org")
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

    func testVerificationEmailError() {
        let parseError = ParseError(code: .internalServer, message: "Object not found")

        var subscriptions = Set<AnyCancellable>()
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(parseError)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Verification user1")
        let publisher = User.verificationEmailPublisher(email: "hello@parse.org")
            .sink(receiveCompletion: { result in

                if case .finished = result {
                    XCTFail("Should have thrown ParseError")
                }
                expectation1.fulfill()

        }, receiveValue: { _ in
            XCTFail("Should have thrown ParseError")
        })
        publisher.store(in: &subscriptions)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testFetch() {
        login()
        MockURLProtocol.removeAll()
        XCTAssertNotNil(User.current?.objectId)

        guard let user = User.current else {
            XCTFail("Should unwrap")
            return
        }

        var serverResponse = LoginSignupResponse()
        serverResponse.createdAt = User.current?.createdAt
        serverResponse.updatedAt = User.current?.updatedAt?.addingTimeInterval(+300)
        serverResponse.sessionToken = "newValue"
        serverResponse.username = "stop"

        var subscriptions = Set<AnyCancellable>()
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Become user1")
        let publisher = user.fetchPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { fetched in

            XCTAssertEqual(fetched.objectId, serverResponse.objectId)

            guard let userFromKeychain = BaseParseUser.current else {
                XCTFail("Couldn't get CurrentUser from Keychain")
                return
            }

            XCTAssertEqual(userFromKeychain.objectId, serverResponse.objectId)
        })
        publisher.store(in: &subscriptions)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testSave() {
        login()
        MockURLProtocol.removeAll()
        XCTAssertNotNil(User.current?.objectId)

        guard let user = User.current else {
            XCTFail("Should unwrap")
            return
        }

        var serverResponse = LoginSignupResponse()
        serverResponse.createdAt = User.current?.createdAt
        serverResponse.updatedAt = User.current?.updatedAt?.addingTimeInterval(+300)
        serverResponse.sessionToken = "newValue"
        serverResponse.username = "stop"

        var subscriptions = Set<AnyCancellable>()
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Become user1")
        let publisher = user.savePublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { saved in

            XCTAssertEqual(saved.objectId, serverResponse.objectId)

            guard let userFromKeychain = BaseParseUser.current else {
                XCTFail("Couldn't get CurrentUser from Keychain")
                return
            }

            XCTAssertEqual(userFromKeychain.objectId, serverResponse.objectId)
        })
        publisher.store(in: &subscriptions)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testDelete() {
        login()
        MockURLProtocol.removeAll()
        XCTAssertNotNil(User.current?.objectId)

        guard let user = User.current else {
            XCTFail("Should unwrap")
            return
        }

        let serverResponse = NoBody()

        var subscriptions = Set<AnyCancellable>()
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let expectation1 = XCTestExpectation(description: "Become user1")
        let publisher = user.deletePublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { _ in

            if BaseParseUser.current != nil {
                XCTFail("Couldn't get CurrentUser from Keychain")
            }
        })
        publisher.store(in: &subscriptions)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testFetchAll() {
        login()
        MockURLProtocol.removeAll()
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Fetch")

        guard var user = User.current else {
                XCTFail("Should unwrap dates")
            expectation1.fulfill()
                return
        }

        user.updatedAt = user.updatedAt?.addingTimeInterval(+300)
        user.customKey = "newValue"
        let userOnServer = QueryResponse<User>(results: [user], count: 1)

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(userOnServer)
            //Get dates in correct format from ParseDecoding strategy
            let encoded1 = try ParseCoding.jsonEncoder().encode(user)
            user = try user.getDecoder().decode(User.self, from: encoded1)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            expectation1.fulfill()
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let publisher = [user].fetchAllPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { fetched in

            fetched.forEach {
                switch $0 {
                case .success(let fetched):
                    XCTAssert(fetched.hasSameObjectId(as: user))
                    guard let fetchedCreatedAt = fetched.createdAt,
                        let fetchedUpdatedAt = fetched.updatedAt else {
                            XCTFail("Should unwrap dates")
                            expectation1.fulfill()
                            return
                    }
                    guard let originalCreatedAt = user.createdAt,
                        let originalUpdatedAt = user.updatedAt,
                        let serverUpdatedAt = user.updatedAt else {
                            XCTFail("Should unwrap dates")
                            expectation1.fulfill()
                            return
                    }
                    XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
                    XCTAssertEqual(fetchedUpdatedAt, originalUpdatedAt)
                    XCTAssertEqual(fetchedUpdatedAt, serverUpdatedAt)
                    XCTAssertEqual(User.current?.customKey, user.customKey)

                    //Should be updated in memory
                    guard let updatedCurrentDate = User.current?.updatedAt else {
                        XCTFail("Should unwrap current date")
                        expectation1.fulfill()
                        return
                    }
                    XCTAssertEqual(updatedCurrentDate, serverUpdatedAt)

                    #if !os(Linux)
                    //Should be updated in Keychain
                    guard let keychainUser: CurrentUserContainer<BaseParseUser>
                        = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser),
                        let keychainUpdatedCurrentDate = keychainUser.currentUser?.updatedAt else {
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

        wait(for: [expectation1], timeout: 20.0)
    }

    func testSaveAll() {
        login()
        MockURLProtocol.removeAll()
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")

        guard var user = User.current else {
                XCTFail("Should unwrap dates")
            expectation1.fulfill()
                return
        }

        user.updatedAt = user.updatedAt?.addingTimeInterval(+300)
        user.customKey = "newValue"
        let userOnServer = [BatchResponseItem<User>(success: user, error: nil)]

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(userOnServer)
            //Get dates in correct format from ParseDecoding strategy
            let encoded1 = try ParseCoding.jsonEncoder().encode(user)
            user = try user.getDecoder().decode(User.self, from: encoded1)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            expectation1.fulfill()
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let publisher = [user].saveAllPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { saved in

            saved.forEach {
                switch $0 {
                case .success(let saved):
                    XCTAssert(saved.hasSameObjectId(as: user))
                    guard let savedCreatedAt = saved.createdAt,
                        let savedUpdatedAt = saved.updatedAt else {
                            XCTFail("Should unwrap dates")
                            expectation1.fulfill()
                            return
                    }
                    guard let originalCreatedAt = user.createdAt,
                        let originalUpdatedAt = user.updatedAt,
                        let serverUpdatedAt = user.updatedAt else {
                            XCTFail("Should unwrap dates")
                            expectation1.fulfill()
                            return
                    }
                    XCTAssertEqual(savedCreatedAt, originalCreatedAt)
                    XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
                    XCTAssertEqual(savedUpdatedAt, serverUpdatedAt)
                    XCTAssertEqual(User.current?.customKey, user.customKey)

                    //Should be updated in memory
                    guard let updatedCurrentDate = User.current?.updatedAt else {
                        XCTFail("Should unwrap current date")
                        expectation1.fulfill()
                        return
                    }
                    XCTAssertEqual(updatedCurrentDate, serverUpdatedAt)

                    #if !os(Linux)
                    //Should be updated in Keychain
                    guard let keychainUser: CurrentUserContainer<BaseParseUser>
                        = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentUser),
                        let keychainUpdatedCurrentDate = keychainUser.currentUser?.updatedAt else {
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

        wait(for: [expectation1], timeout: 20.0)
    }

    func testDeleteAll() {
        login()
        MockURLProtocol.removeAll()
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")

        guard let user = User.current else {
                XCTFail("Should unwrap dates")
                expectation1.fulfill()
                return
        }

        let userOnServer = [BatchResponseItem<NoBody>(success: NoBody(), error: nil)]

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(userOnServer)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            expectation1.fulfill()
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let publisher = [user].deleteAllPublisher()
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

        wait(for: [expectation1], timeout: 20.0)
    }
}

#endif
