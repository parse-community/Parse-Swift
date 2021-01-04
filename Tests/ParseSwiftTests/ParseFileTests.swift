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
        fileManager.removeDirectoryContents(directory2) { _ in
            expectation2.fulfill()
        }
        wait(for: [expectation1, expectation2], timeout: 20.0)
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

        let file2 = ParseFile(cloudURL: url)

        let command2 = file2.uploadFileCommand()
        XCTAssertNotNil(command2)
        XCTAssertEqual(command2.path.urlComponent, "/files/file")
        XCTAssertEqual(command2.method, API.Method.POST)
        XCTAssertNil(command2.params)
        XCTAssertNil(command2.body)
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

        var file2 = ParseFile(cloudURL: url)
        file2.url = url
        let command2 = file2.deleteFileCommand()
        XCTAssertNotNil(command2)
        XCTAssertEqual(command2.path.urlComponent, "/files/file")
        XCTAssertEqual(command2.method, API.Method.DELETE)
        XCTAssertNil(command2.params)
        XCTAssertNil(command2.body)
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

        let file2 = ParseFile(cloudURL: url)
        let command2 = file2.downloadFileCommand()
        XCTAssertNotNil(command2)
        XCTAssertEqual(command2.path.urlComponent, "/files/file")
        XCTAssertEqual(command2.method, API.Method.GET)
        XCTAssertNil(command2.params)
        XCTAssertNil(command2.body)
    }

    func testLocalUUID() throws {
        guard let sampleData = "Hello World".data(using: .utf8) else {
            throw ParseError(code: .unknownError, message: "Should have converted to data")
        }
        let parseFile = ParseFile(name: "sampleData.txt", data: sampleData)
        let localId = parseFile.localId
        XCTAssertNotNil(localId)
        XCTAssertEqual(localId,
                       parseFile.localId,
                       "localId should remain the same no matter how many times the getter is called")
    }

    func testFileEquality() throws {
        guard let sampleData = "Hello World".data(using: .utf8) else {
            throw ParseError(code: .unknownError, message: "Should have converted to data")
        }

        guard let url1 = URL(string: "https://parseplatform.org/img/logo.svg"),
              let url2 = URL(string: "https://parseplatform.org/img/logo2.svg") else {
            throw ParseError(code: .unknownError, message: "Should have created urls")
        }

        var parseFile1 = ParseFile(name: "sampleData.txt", data: sampleData)
        parseFile1.url = url1
        var parseFile2 = ParseFile(name: "sampleData2.txt", data: sampleData)
        parseFile2.url = url2
        var parseFile3 = ParseFile(name: "sampleData3.txt", data: sampleData)
        parseFile3.url = url1
        XCTAssertNotEqual(parseFile1, parseFile2, "different urls, url takes precedence over localId")
        XCTAssertEqual(parseFile1, parseFile3, "same urls")
        parseFile1.url = nil
        parseFile2.url = nil
        XCTAssertNotEqual(parseFile1, parseFile2, "no urls, but localIds shoud be different")
        let uuid = UUID()
        parseFile1.localId = uuid
        parseFile2.localId = uuid
        XCTAssertEqual(parseFile1, parseFile2, "no urls, but localIds shoud be the same")
    }

    func testSave() throws {
        guard let sampleData = "Hello World".data(using: .utf8) else {
            throw ParseError(code: .unknownError, message: "Should have converted to data")
        }
        let parseFile = ParseFile(name: "sampleData.txt",
                                  data: sampleData,
                                  metadata: ["Testing": "123"],
                                  tags: ["Hey": "now"])

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
        guard let sampleData = "Hello World".data(using: .utf8) else {
            throw ParseError(code: .unknownError, message: "Should have converted to data")
        }
        let parseFile = ParseFile(data: sampleData, mimeType: "application/txt")

        // swiftlint:disable:next line_length
        guard let url = URL(string: "http://localhost:1337/1/files/applicationId/89d74fcfa4faa5561799e5076593f67c_file") else {
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
        let tempFilePath = URL(fileURLWithPath: "\(temporaryDirectory)sampleData.txt")
        guard let sampleData = "Hello World".data(using: .utf8) else {
            throw ParseError(code: .unknownError, message: "Should have converted to data")
        }
        try sampleData.write(to: tempFilePath)

        let parseFile = ParseFile(name: "sampleData.txt", localURL: tempFilePath)

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
        XCTAssertEqual(savedFile.localURL, tempFilePath)
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
        XCTAssertNotNil(savedFile.localURL)
    }

    func testCloudFileProgress() throws {
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

        let savedFile = try parseFile.save { (_, _, totalWritten, totalExpected) in
            let currentProgess = Double(totalWritten)/Double(totalExpected) * 100
            XCTAssertGreaterThan(currentProgess, -1)
        }
        XCTAssertEqual(savedFile.name, response.name)
        XCTAssertEqual(savedFile.url, response.url)
        XCTAssertEqual(savedFile.cloudURL, tempFilePath)
        XCTAssertNotNil(savedFile.localURL)
    }

    func testCloudFileCancel() throws {
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

        let savedFile = try parseFile.save { (task, _, totalWritten, totalExpected) in
            let currentProgess = Double(totalWritten)/Double(totalExpected) * 100
            if currentProgess > 10 {
                task.cancel()
            }
        }
        XCTAssertEqual(savedFile.name, response.name)
        XCTAssertEqual(savedFile.url, response.url)
        XCTAssertEqual(savedFile.cloudURL, tempFilePath)
        XCTAssertNotNil(savedFile.localURL)
    }

    func testSaveFileStream() throws {
        let tempFilePath = URL(fileURLWithPath: "\(temporaryDirectory)sampleData.dat")
        guard let sampleData = "Hello World".data(using: .utf8) else {
            throw ParseError(code: .unknownError, message: "Should have converted to data")
        }
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

        guard let stream = InputStream(fileAtPath: tempFilePath.relativePath) else {
            throw ParseError(code: .unknownError, message: "Should have created file stream")
        }
        try parseFile.save(options: [], stream: stream, progress: nil)
    }

    func testSaveFileStreamProgress() throws {
        let tempFilePath = URL(fileURLWithPath: "\(temporaryDirectory)sampleData.dat")
        guard let sampleData = "Hello World".data(using: .utf8) else {
            throw ParseError(code: .unknownError, message: "Should have converted to data")
        }
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

        guard let stream = InputStream(fileAtPath: tempFilePath.relativePath) else {
            throw ParseError(code: .unknownError, message: "Should have created file stream")
        }

        try parseFile.save(stream: stream) { (_, _, totalWritten, totalExpected) in
            let currentProgess = Double(totalWritten)/Double(totalExpected) * 100
            XCTAssertGreaterThan(currentProgess, -1)
        }
    }

    func testSaveFileStreamCancel() throws {
        let tempFilePath = URL(fileURLWithPath: "\(temporaryDirectory)sampleData.dat")
        guard let sampleData = "Hello World".data(using: .utf8) else {
            throw ParseError(code: .unknownError, message: "Should have converted to data")
        }
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

        guard let stream = InputStream(fileAtPath: tempFilePath.relativePath) else {
            throw ParseError(code: .unknownError, message: "Should have created file stream")
        }

        try parseFile.save(stream: stream) { (task, _, totalWritten, totalExpected) in
            let currentProgess = Double(totalWritten)/Double(totalExpected) * 100
            if currentProgess > 10 {
                task.cancel()
            }
        }
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
        XCTAssertNotNil(fetchedFile.localURL)
    }

    func testFetchFileProgress() throws {
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

        let fetchedFile = try parseFile.fetch { (_, _, totalDownloaded, totalExpected) in
            let currentProgess = Double(totalDownloaded)/Double(totalExpected) * 100
            XCTAssertGreaterThan(currentProgess, -1)
        }
        XCTAssertEqual(fetchedFile.name, response.name)
        XCTAssertEqual(fetchedFile.url, response.url)
        XCTAssertNotNil(fetchedFile.localURL)
    }

    func testFetchFileStream() throws {
        let tempFilePath = URL(fileURLWithPath: "\(temporaryDirectory)sampleData.dat")
        guard let sampleData = "Hello World".data(using: .utf8) else {
            throw ParseError(code: .unknownError, message: "Should have converted to data")
        }
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

        guard let stream = InputStream(fileAtPath: tempFilePath.relativePath) else {
            throw ParseError(code: .unknownError, message: "Should have created file stream")
        }
        try parseFile.fetch(stream: stream)
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

    // swiftlint:disable:next inclusive_language
    func testDeleteFileNoMasterKey() throws {
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

        XCTAssertThrowsError(try parseFile.delete(options: [.removeMimeType]))
    }

    func testSaveAysnc() throws {

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

        let expectation1 = XCTestExpectation(description: "ParseFile async")
        parseFile.save { result in

            switch result {
            case .success(let saved):
                XCTAssertEqual(saved.name, response.name)
                XCTAssertEqual(saved.url, response.url)

            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testSaveFileProgressAsync() throws {
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

        let expectation1 = XCTestExpectation(description: "ParseFile async")
        parseFile.save(progress: { (_, _, totalWritten, totalExpected) in
            let currentProgess = Double(totalWritten)/Double(totalExpected) * 100
            XCTAssertGreaterThan(currentProgess, -1)
        }) { result in // swiftlint:disable:this multiple_closures_with_trailing_closure

            switch result {
            case .success(let saved):
                XCTAssertEqual(saved.name, response.name)
                XCTAssertEqual(saved.url, response.url)

            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testSaveFileCancelAsync() throws {
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

        let expectation1 = XCTestExpectation(description: "ParseFile async")
        parseFile.save(progress: { (task, _, totalWritten, totalExpected) in
            let currentProgess = Double(totalWritten)/Double(totalExpected) * 100
            if currentProgess > 10 {
                task.cancel()
            }
        }) { result in // swiftlint:disable:this multiple_closures_with_trailing_closure

            switch result {
            case .success(let saved):
                XCTAssertEqual(saved.name, response.name)
                XCTAssertEqual(saved.url, response.url)

            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testSaveWithSpecifyingMimeAysnc() throws {

        guard let sampleData = "Hello World".data(using: .utf8) else {
            throw ParseError(code: .unknownError, message: "Should have converted to data")
        }
        let parseFile = ParseFile(data: sampleData, mimeType: "application/txt")

        // swiftlint:disable:next line_length
        guard let url = URL(string: "http://localhost:1337/1/files/applicationId/89d74fcfa4faa5561799e5076593f67c_file") else {
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

        let expectation1 = XCTestExpectation(description: "ParseFile async")
        parseFile.save { result in

            switch result {
            case .success(let saved):
                XCTAssertEqual(saved.name, response.name)
                XCTAssertEqual(saved.url, response.url)

            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testSaveLocalFileAysnc() throws {

        let tempFilePath = URL(fileURLWithPath: "\(temporaryDirectory)sampleData.txt")
        guard let sampleData = "Hello World".data(using: .utf8) else {
            throw ParseError(code: .unknownError, message: "Should have converted to data")
        }
        try sampleData.write(to: tempFilePath)

        let parseFile = ParseFile(name: "sampleData.txt", localURL: tempFilePath)

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

        let expectation1 = XCTestExpectation(description: "ParseFile async")
        parseFile.save { result in

            switch result {
            case .success(let saved):
                XCTAssertEqual(saved.name, response.name)
                XCTAssertEqual(saved.url, response.url)
                XCTAssertEqual(saved.localURL, tempFilePath)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testSaveCloudFileAysnc() throws {

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

        let expectation1 = XCTestExpectation(description: "ParseFile async")
        parseFile.save { result in

            switch result {
            case .success(let saved):
                XCTAssertEqual(saved.name, response.name)
                XCTAssertEqual(saved.url, response.url)
                XCTAssertEqual(saved.cloudURL, tempFilePath)
                XCTAssertNotNil(saved.localURL)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testFetchFileAysnc() throws {

        // swiftlint:disable:next line_length
        guard let parseFileURL = URL(string: "http://localhost:1337/1/files/applicationId/7793939a2e59b98138c1bbf2412a060c_logo.svg") else {
            XCTFail("Should create URL")
            return
        }
        var parseFile = ParseFile(name: "7793939a2e59b98138c1bbf2412a060c_logo.svg", cloudURL: parseFileURL)
        parseFile.url = parseFileURL

        let response = FileUploadResponse(name: "7793939a2e59b98138c1bbf2412a060c_logo.svg",
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

        let expectation1 = XCTestExpectation(description: "ParseFile async")
        parseFile.fetch { result in

            switch result {
            case .success(let fetched):
                XCTAssertEqual(fetched.name, response.name)
                XCTAssertEqual(fetched.url, response.url)
                XCTAssertNotNil(fetched.localURL)

            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testSaveCloudFileProgressAysnc() throws {

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

        let expectation1 = XCTestExpectation(description: "ParseFile async")
        parseFile.save(progress: { (_, _, totalWritten, totalExpected) in
            let currentProgess = Double(totalWritten)/Double(totalExpected) * 100
            XCTAssertGreaterThan(currentProgess, -1)
        }) { result in // swiftlint:disable:this multiple_closures_with_trailing_closure

            switch result {
            case .success(let saved):
                XCTAssertEqual(saved.name, response.name)
                XCTAssertEqual(saved.url, response.url)
                XCTAssertEqual(saved.cloudURL, tempFilePath)
                XCTAssertNotNil(saved.localURL)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testFetchFileProgressAsync() throws {
        // swiftlint:disable:next line_length
        guard let parseFileURL = URL(string: "http://localhost:1337/1/files/applicationId/6f9988ab5faa28f7247664c6ffd9fd85_logo.svg") else {
            XCTFail("Should create URL")
            return
        }
        var parseFile = ParseFile(name: "6f9988ab5faa28f7247664c6ffd9fd85_logo.svg", cloudURL: parseFileURL)
        parseFile.url = parseFileURL

        let response = FileUploadResponse(name: "6f9988ab5faa28f7247664c6ffd9fd85_logo.svg",
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

        let expectation1 = XCTestExpectation(description: "ParseFile async")
        parseFile.fetch(progress: { (_, _, totalDownloaded, totalExpected) in
            let currentProgess = Double(totalDownloaded)/Double(totalExpected) * 100
            XCTAssertGreaterThan(currentProgess, -1)
        }) { result in // swiftlint:disable:this multiple_closures_with_trailing_closure

            switch result {
            case .success(let fetched):
                XCTAssertEqual(fetched.name, response.name)
                XCTAssertEqual(fetched.url, response.url)
                XCTAssertNotNil(fetched.localURL)

            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testFetchFileCancelAsync() throws {
        // swiftlint:disable:next line_length
        guard let parseFileURL = URL(string: "http://localhost:1337/1/files/applicationId/7793939a2e59b98138c1bbf2412a060c_logo.svg") else {
            XCTFail("Should create URL")
            return
        }
        var parseFile = ParseFile(name: "7793939a2e59b98138c1bbf2412a060c_logo.svg", cloudURL: parseFileURL)
        parseFile.url = parseFileURL

        let response = FileUploadResponse(name: "7793939a2e59b98138c1bbf2412a060c_logo.svg",
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

        let expectation1 = XCTestExpectation(description: "ParseFile async")
        parseFile.fetch(progress: { (task, _, totalDownloaded, totalExpected) in
            let currentProgess = Double(totalDownloaded)/Double(totalExpected) * 100
            if currentProgess > 10 {
                task.cancel()
            }
        }) { result in // swiftlint:disable:this multiple_closures_with_trailing_closure

            switch result {
            case .success(let fetched):
                XCTAssertEqual(fetched.name, response.name)
                XCTAssertEqual(fetched.url, response.url)
                XCTAssertNotNil(fetched.localURL)

            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testDeleteFileAysnc() throws {
        // swiftlint:disable:next line_length
        guard let parseFileURL = URL(string: "http://localhost:1337/1/files/applicationId/1b0683d529463e173cbf8046d7d9a613_logo.svg") else {
            XCTFail("Should create URL")
            return
        }
        var parseFile = ParseFile(name: "1b0683d529463e173cbf8046d7d9a613_logo.svg", cloudURL: parseFileURL)
        parseFile.url = parseFileURL

        let response = FileUploadResponse(name: "1b0683d529463e173cbf8046d7d9a613_logo.svg",
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

        let expectation1 = XCTestExpectation(description: "ParseFile async")
        parseFile.delete(options: [.useMasterKey]) { error in

            guard let error = error else {
                expectation1.fulfill()
                return
            }
            XCTFail(error.localizedDescription)
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    // swiftlint:disable:next inclusive_language
    func testDeleteNoMasterKeyFileAysnc() throws {
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

        let expectation1 = XCTestExpectation(description: "ParseFile async")
        parseFile.delete(options: [.removeMimeType]) { error in

            guard error != nil else {
                XCTFail("Should have thrown error")
                expectation1.fulfill()
                return
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }
} // swiftlint:disable:this file_length
