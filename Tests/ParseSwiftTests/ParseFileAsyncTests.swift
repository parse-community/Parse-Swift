//
//  ParseFileAsyncTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 9/28/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if swift(>=5.5) && canImport(_Concurrency) && !os(Linux) && !os(Android)
import Foundation
import XCTest
@testable import ParseSwift

@available(macOS 12.0, iOS 15.0, macCatalyst 15.0, watchOS 9.0, tvOS 15.0, *)
class ParseFileAsyncTests: XCTestCase { // swiftlint:disable:this type_body_length
    let temporaryDirectory = "\(NSTemporaryDirectory())test/"

    struct FileUploadResponse: Codable {
        let name: String
        let url: URL
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
        guard let fileManager = ParseFileManager() else {
            throw ParseError(code: .unknownError, message: "Should have initialized file manage")
        }
        try fileManager.createDirectoryIfNeeded(temporaryDirectory)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        MockURLProtocol.removeAll()
        #if !os(Linux) && !os(Android)
        try KeychainStore.shared.deleteAll()
        #endif
        try ParseStorage.shared.deleteAll()

        guard let fileManager = ParseFileManager(),
              let defaultDirectoryPath = fileManager.defaultDataDirectoryPath else {
            throw ParseError(code: .unknownError, message: "Should have initialized file manage")
        }
        let directory = URL(fileURLWithPath: temporaryDirectory, isDirectory: true)
        let expectation1 = XCTestExpectation(description: "Delete files1")
        fileManager.removeDirectoryContents(directory) { error in
            guard let error = error else {
                expectation1.fulfill()
                return
            }
            XCTFail(error.localizedDescription)
            expectation1.fulfill()
        }
        let directory2 = defaultDirectoryPath
            .appendingPathComponent(ParseConstants.fileDownloadsDirectory, isDirectory: true)
        let expectation2 = XCTestExpectation(description: "Delete files2")
        fileManager.removeDirectoryContents(directory2) { _ in
            expectation2.fulfill()
        }
        wait(for: [expectation1, expectation2], timeout: 20.0)
    }

    @MainActor
    func testFetch() async throws {

        // swiftlint:disable:next line_length
        guard let parseFileURL = URL(string: "http://localhost:1337/1/files/applicationId/d3a37aed0672a024595b766f97133615_logo.svg") else {
            XCTFail("Should create URL")
            return
        }
        var parseFile = ParseFile(name: "d3a37aed0672a024595b766f97133615_logo.svg", cloudURL: parseFileURL)
        parseFile.url = parseFileURL

        let response = FileUploadResponse(name: "d3a37aed0672a024595b766f97133615_logo.svg",
                                          url: parseFileURL)
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(response)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let fetched = try await parseFile.fetch()
        XCTAssertEqual(fetched.name, response.name)
        XCTAssertEqual(fetched.url, response.url)
        XCTAssertNotNil(fetched.localURL)
    }

    @MainActor
    func testFetchFileProgress() async throws {

        // swiftlint:disable:next line_length
        guard let parseFileURL = URL(string: "http://localhost:1337/1/files/applicationId/d3a37aed0672a024595b766f97133615_logo.svg") else {
            XCTFail("Should create URL")
            return
        }
        var parseFile = ParseFile(name: "d3a37aed0672a024595b766f97133615_logo.svg", cloudURL: parseFileURL)
        parseFile.url = parseFileURL

        let response = FileUploadResponse(name: "d3a37aed0672a024595b766f97133615_logo.svg",
                                          url: parseFileURL)
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(response)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let fetched = try await parseFile.fetch(progress: { (_, _, totalDownloaded, totalExpected) in
            let currentProgess = Double(totalDownloaded)/Double(totalExpected) * 100
            XCTAssertGreaterThan(currentProgess, -1)
        })
        XCTAssertEqual(fetched.name, response.name)
        XCTAssertEqual(fetched.url, response.url)
        XCTAssertNotNil(fetched.localURL)
    }

    @MainActor
    func testSave() async throws {

        guard let sampleData = "Hello World".data(using: .utf8) else {
            throw ParseError(code: .unknownError, message: "Should have converted to data")
        }
        let parseFile = ParseFile(name: "sampleData.txt", data: sampleData)

        // swiftlint:disable:next line_length
        guard let url = URL(string: "http://localhost:1337/1/files/applicationId/89d74fcfa4faa5561799e5076593f67c_sampleData.txt") else {
            XCTFail("Should create URL")
            return
        }
        let response = FileUploadResponse(name: "89d74fcfa4faa5561799e5076593f67c_\(parseFile.name)", url: url)
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(response)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let fetched = try await parseFile.save()
        XCTAssertEqual(fetched.name, response.name)
        XCTAssertEqual(fetched.url, response.url)
    }

    @MainActor
    func testSaveFileProgress() async throws {

        guard let sampleData = "Hello World".data(using: .utf8) else {
            throw ParseError(code: .unknownError, message: "Should have converted to data")
        }
        let parseFile = ParseFile(name: "sampleData.txt", data: sampleData)

        // swiftlint:disable:next line_length
        guard let url = URL(string: "http://localhost:1337/1/files/applicationId/89d74fcfa4faa5561799e5076593f67c_sampleData.txt") else {
            XCTFail("Should create URL")
            return
        }
        let response = FileUploadResponse(name: "89d74fcfa4faa5561799e5076593f67c_\(parseFile.name)", url: url)
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(response)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let fetched = try await parseFile.save(progress: { (_, _, totalDownloaded, totalExpected) in
            let currentProgess = Double(totalDownloaded)/Double(totalExpected) * 100
            XCTAssertGreaterThan(currentProgess, -1)
        })
        XCTAssertEqual(fetched.name, response.name)
        XCTAssertEqual(fetched.url, response.url)
    }

    @MainActor
    func testDelete() async throws {

        // swiftlint:disable:next line_length
        guard let parseFileURL = URL(string: "http://localhost:1337/1/files/applicationId/d3a37aed0672a024595b766f97133615_logo.svg") else {
            XCTFail("Should create URL")
            return
        }
        var parseFile = ParseFile(name: "d3a37aed0672a024595b766f97133615_logo.svg", cloudURL: parseFileURL)
        parseFile.url = parseFileURL

        let response = FileUploadResponse(name: "d3a37aed0672a024595b766f97133615_logo.svg",
                                          url: parseFileURL)
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(response)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        _ = try await parseFile.delete(options: [.useMasterKey])
    }
}
#endif
