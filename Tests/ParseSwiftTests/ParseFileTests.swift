//
//  ParseFileTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 12/23/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class ParseFileTests: XCTestCase { // swiftlint:disable:this type_body_length

    let sampleData = Data([0x0, 0x1, 0x2, 0x3,
                           0x4, 0x5, 0x6, 0x7,
                           0x8, 0x9, 0xA, 0xB,
                           0xC, 0xD, 0xE, 0xF])

    let temporaryDirectory = "\(NSTemporaryDirectory())test/"

    struct FileUploadResponse: Codable {
        let name: String
        let url: URL
    }

    override func setUpWithError() throws {
        super.setUp()
        guard let url = URL(string: "http://localhost:1337/1") else {
            XCTFail("Should create valid URL")
            return
        }
        ParseSwift.initialize(applicationId: "applicationId",
                              clientKey: "clientKey",
                              masterKey: "masterKey",
                              serverURL: url)

        guard let fileManager = ParseFileManager() else {
            throw ParseError(code: .unknownError, message: "Should have initialized file manage")
        }
        try fileManager.createDirectoryIfNeeded(temporaryDirectory)
        ParseSwift.setupForTesting()
    }

    override func tearDownWithError() throws {
        super.tearDown()
        MockURLProtocol.removeAll()
        try KeychainStore.shared.deleteAll()
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
        fileManager.removeDirectoryContents(directory2) { error in
            guard let error = error else {
                expectation2.fulfill()
                return
            }
            XCTFail(error.localizedDescription)
            expectation2.fulfill()
        }
        wait(for: [expectation1, expectation2], timeout: 10.0)
    }

    func testUploadCommand() {
        guard let url = URL(string: "http://localhost/") else {
            XCTFail("Should have created url")
            return
        }
        let file = ParseFile(name: "a", cloudURL: url)

        let command = file.uploadFileCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/files/a")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertNil(command.params)
        XCTAssertNil(command.body)
        XCTAssertNil(command.data)

        let file2 = ParseFile(cloudURL: url)

        let command2 = file2.uploadFileCommand()
        XCTAssertNotNil(command2)
        XCTAssertEqual(command2.path.urlComponent, "/files/file")
        XCTAssertEqual(command2.method, API.Method.POST)
        XCTAssertNil(command2.params)
        XCTAssertNil(command2.body)
        XCTAssertNil(command2.data)
    }

    func testDeleteCommand() {
        guard let url = URL(string: "http://localhost/") else {
            XCTFail("Should have created url")
            return
        }
        var file = ParseFile(name: "a", cloudURL: url)
        file.url = url
        let command = file.deleteFileCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/files/a")
        XCTAssertEqual(command.method, API.Method.DELETE)
        XCTAssertNil(command.params)
        XCTAssertNil(command.body)
        XCTAssertNil(command.data)

        var file2 = ParseFile(cloudURL: url)
        file2.url = url
        let command2 = file2.deleteFileCommand()
        XCTAssertNotNil(command2)
        XCTAssertEqual(command2.path.urlComponent, "/files/file")
        XCTAssertEqual(command2.method, API.Method.DELETE)
        XCTAssertNil(command2.params)
        XCTAssertNil(command2.body)
        XCTAssertNil(command2.data)
    }

    func testDownloadCommand() {
        guard let url = URL(string: "http://localhost/") else {
            XCTFail("Should have created url")
            return
        }
        var file = ParseFile(name: "a", cloudURL: url)
        file.url = url
        let command = file.downloadFileCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/files/a")
        XCTAssertEqual(command.method, API.Method.GET)
        XCTAssertNil(command.params)
        XCTAssertNil(command.body)
        XCTAssertNil(command.data)

        let file2 = ParseFile(cloudURL: url)
        let command2 = file2.downloadFileCommand()
        XCTAssertNotNil(command2)
        XCTAssertEqual(command2.path.urlComponent, "/files/file")
        XCTAssertEqual(command2.method, API.Method.GET)
        XCTAssertNil(command2.params)
        XCTAssertNil(command2.body)
        XCTAssertNil(command2.data)
    }

    func testSave() throws {

        var parseFile = ParseFile(name: "sampleData.data", data: sampleData)
        parseFile.mimeType = "application/octet-stream"

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

        let savedFile = try parseFile.save()
        XCTAssertEqual(savedFile.name, response.name)
        XCTAssertEqual(savedFile.url, response.url)
    }

    func testSaveWithSpecifyingMime() throws {
        let parseFile = ParseFile(name: "sampleData.data", data: sampleData)

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

        let savedFile = try parseFile.save()
        XCTAssertEqual(savedFile.name, response.name)
        XCTAssertEqual(savedFile.url, response.url)
    }

    func testSaveLocalFile() throws {
        let tempFilePath = URL(fileURLWithPath: "\(temporaryDirectory)sampleData.dat")
        try sampleData.write(to: tempFilePath)

        let parseFile = ParseFile(name: "sampleData.data", localURL: tempFilePath)

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

        let savedFile = try parseFile.save()
        XCTAssertEqual(savedFile.name, response.name)
        XCTAssertEqual(savedFile.url, response.url)
    }

    func testSaveCloudFile() throws {
        guard let tempFilePath = URL(string: "https://parseplatform.org/img/logo.svg") else {
            XCTFail("Should create URL")
            return
        }

        let parseFile = ParseFile(name: "logo.svg", cloudURL: tempFilePath)

        // swiftlint:disable:next line_length
        guard let url = URL(string: "http://localhost:1337/1/files/applicationId/89d74fcfa4faa5561799e5076593f67c_logo.svg") else {
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

        let savedFile = try parseFile.save()
        XCTAssertEqual(savedFile.name, response.name)
        XCTAssertEqual(savedFile.url, response.url)
        XCTAssertEqual(savedFile.cloudURL, tempFilePath)
    }

    func testSaveFileStream() throws {
        let tempFilePath = URL(fileURLWithPath: "\(temporaryDirectory)sampleData.dat")
        try sampleData.write(to: tempFilePath)

        var parseFile = ParseFile(name: "sampleData.data", localURL: tempFilePath)

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

        try parseFile.save(options: [], progress: nil, stream: InputStream(fileAtPath: tempFilePath.relativePath))
    }

    func testFetchFile() throws {
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

        let fetchedFile = try parseFile.fetch()
        XCTAssertEqual(fetchedFile.name, response.name)
        XCTAssertEqual(fetchedFile.url, response.url)
    }

    func testDeleteFile() throws {
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

        try parseFile.delete(options: [.useMasterKey])
    }
}
