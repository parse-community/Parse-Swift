//
//  ParseFileTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 12/23/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
@testable import ParseSwift

class ParseFileTests: XCTestCase { // swiftlint:disable:this type_body_length

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
                              primaryKey: "primaryKey",
                              serverURL: url,
                              testing: true)

        guard let fileManager = ParseFileManager() else {
            throw ParseError(code: .otherCause, message: "Should have initialized file manage")
        }
        try fileManager.createDirectoryIfNeeded(temporaryDirectory)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        MockURLProtocol.removeAll()
        URLSession.parse.configuration.urlCache?.removeAllCachedResponses()
        #if !os(Linux) && !os(Android) && !os(Windows)
        try KeychainStore.shared.deleteAll()
        #endif
        try ParseStorage.shared.deleteAll()

        guard let fileManager = ParseFileManager() else {
            throw ParseError(code: .otherCause, message: "Should have initialized file manage")
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
        let directory2 = try ParseFileManager.downloadDirectory()
        let expectation2 = XCTestExpectation(description: "Delete files2")
        fileManager.removeDirectoryContents(directory2) { _ in
            expectation2.fulfill()
        }
        wait(for: [expectation1, expectation2], timeout: 20.0)
    }

    func testUploadCommand() throws {
        guard let url = URL(string: "http://localhost/") else {
            XCTFail("Should have created url")
            return
        }
        let file = ParseFile(name: "a", cloudURL: url)

        let command = try file.uploadFileCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/files/a")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertNil(command.params)
        XCTAssertNil(command.body)

        let file2 = ParseFile(cloudURL: url)

        let command2 = try file2.uploadFileCommand()
        XCTAssertNotNil(command2)
        XCTAssertEqual(command2.path.urlComponent, "/files/file")
        XCTAssertEqual(command2.method, API.Method.POST)
        XCTAssertNil(command2.params)
        XCTAssertNil(command2.body)
    }

    func testUploadCommandDontAllowUpdate() throws {
        guard let url = URL(string: "http://localhost/") else {
            XCTFail("Should have created url")
            return
        }

        var file = ParseFile(cloudURL: url)
        file.url = url
        XCTAssertThrowsError(try file.uploadFileCommand())
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
            throw ParseError(code: .otherCause, message: "Should have converted to data")
        }
        let parseFile = ParseFile(name: "sampleData.txt", data: sampleData)
        let localId = parseFile.id
        XCTAssertNotNil(localId)
        XCTAssertEqual(localId,
                       parseFile.id,
                       "localId should remain the same no matter how many times the getter is called")
    }

    func testFileEquality() throws {
        guard let sampleData = "Hello World".data(using: .utf8) else {
            throw ParseError(code: .otherCause, message: "Should have converted to data")
        }

        guard let url1 = URL(string: "https://parseplatform.org/img/logo.svg"),
              let url2 = URL(string: "https://parseplatform.org/img/logo2.svg") else {
            throw ParseError(code: .otherCause, message: "Should have created urls")
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
        parseFile1.id = uuid
        parseFile2.id = uuid
        XCTAssertEqual(parseFile1, parseFile2, "no urls, but localIds shoud be the same")
    }

    func testDebugString() throws {
        guard let sampleData = "Hello World".data(using: .utf8) else {
            throw ParseError(code: .otherCause, message: "Should have converted to data")
        }
        let parseFile = ParseFile(name: "sampleData.txt",
                                  data: sampleData,
                                  metadata: ["Testing": "123"],
                                  tags: ["Hey": "now"])
        XCTAssertEqual(parseFile.debugDescription,
                       "{\"__type\":\"File\",\"name\":\"sampleData.txt\"}")
        XCTAssertEqual(parseFile.description,
                       "{\"__type\":\"File\",\"name\":\"sampleData.txt\"}")
    }

    func testDebugStringWithFolderInName() throws {
        guard let sampleData = "Hello World".data(using: .utf8) else {
            throw ParseError(code: .otherCause, message: "Should have converted to data")
        }
        let parseFile = ParseFile(name: "myFolder/sampleData.txt",
                                  data: sampleData,
                                  metadata: ["Testing": "123"],
                                  tags: ["Hey": "now"])
        XCTAssertEqual(parseFile.debugDescription,
                       "{\"__type\":\"File\",\"name\":\"myFolder\\/sampleData.txt\"}")
        XCTAssertEqual(parseFile.description,
                       "{\"__type\":\"File\",\"name\":\"myFolder\\/sampleData.txt\"}")
    }

    func testSave() throws {
        guard let sampleData = "Hello World".data(using: .utf8) else {
            throw ParseError(code: .otherCause, message: "Should have converted to data")
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
            throw ParseError(code: .otherCause, message: "Should have converted to data")
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
            throw ParseError(code: .otherCause, message: "Should have converted to data")
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

    func testSaveFileStream() throws {
        let tempFilePath = URL(fileURLWithPath: "\(temporaryDirectory)sampleData.dat")
        guard let sampleData = "Hello World".data(using: .utf8) else {
            throw ParseError(code: .otherCause, message: "Should have converted to data")
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
            throw ParseError(code: .otherCause, message: "Should have created file stream")
        }
        try parseFile.save(options: [], stream: stream, progress: nil)
    }

    func testSaveFileStreamProgress() throws {
        let tempFilePath = URL(fileURLWithPath: "\(temporaryDirectory)sampleData.dat")
        guard let sampleData = "Hello World".data(using: .utf8) else {
            throw ParseError(code: .otherCause, message: "Should have converted to data")
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
            throw ParseError(code: .otherCause, message: "Should have created file stream")
        }

        try parseFile.save(stream: stream) { (_, _, totalWritten, totalExpected) in
            let currentProgess = Double(totalWritten)/Double(totalExpected) * 100
            XCTAssertGreaterThan(currentProgess, -1)
        }
    }

    func testSaveFileStreamCancel() throws {
        let tempFilePath = URL(fileURLWithPath: "\(temporaryDirectory)sampleData.dat")
        guard let sampleData = "Hello World".data(using: .utf8) else {
            throw ParseError(code: .otherCause, message: "Should have converted to data")
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
            throw ParseError(code: .otherCause, message: "Should have created file stream")
        }

        try parseFile.save(stream: stream) { (task, _, totalWritten, totalExpected) in
            let currentProgess = Double(totalWritten)/Double(totalExpected) * 100
            if currentProgess > 10 {
                task.cancel()
            }
        }
    }

    func testUpdateFileError() throws {
        guard let sampleData = "Hello World".data(using: .utf8) else {
            throw ParseError(code: .otherCause, message: "Should have converted to data")
        }
        var parseFile = ParseFile(name: "sampleData.txt",
                                  data: sampleData,
                                  metadata: ["Testing": "123"],
                                  tags: ["Hey": "now"])
        parseFile.url = URL(string: "http://localhost/")

        XCTAssertThrowsError(try parseFile.save())
    }

    func testFetchFileStream() throws {
        let tempFilePath = URL(fileURLWithPath: "\(temporaryDirectory)sampleData.dat")
        guard let sampleData = "Hello World".data(using: .utf8) else {
            throw ParseError(code: .otherCause, message: "Should have converted to data")
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
            throw ParseError(code: .otherCause, message: "Should have created file stream")
        }
        try parseFile.fetch(stream: stream)
    }

    func testSaveAysnc() throws {

        guard let sampleData = "Hello World".data(using: .utf8) else {
            throw ParseError(code: .otherCause, message: "Should have converted to data")
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
            throw ParseError(code: .otherCause, message: "Should have converted to data")
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
            throw ParseError(code: .otherCause, message: "Should have converted to data")
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
            throw ParseError(code: .otherCause, message: "Should have converted to data")
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
            throw ParseError(code: .otherCause, message: "Should have converted to data")
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

    func testUpdateErrorAysnc() throws {

        guard let sampleData = "Hello World".data(using: .utf8) else {
            throw ParseError(code: .otherCause, message: "Should have converted to data")
        }
        var parseFile = ParseFile(name: "sampleData.txt", data: sampleData)
        parseFile.url = URL(string: "http://localhost/")

        let expectation1 = XCTestExpectation(description: "ParseFile async")
        parseFile.save { result in

            switch result {
            case .success:
                XCTFail("Should have returned error")
            case .failure(let error):
                XCTAssertTrue(error.message.contains("File is already"))
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    #if compiler(<5.5.2)
    func testParseURLSessionDelegates() throws {
        // swiftlint:disable:next line_length
        let dowloadTask = URLSession.shared.downloadTask(with: .init(fileURLWithPath: "http://localhost:1337/1/files/applicationId/d3a37aed0672a024595b766f97133615_logo.svg"))
        let task = dowloadTask as URLSessionTask
        // swiftlint:disable:next line_length
        let uploadCompletion: ((URLSessionTask, Int64, Int64, Int64) -> Void) = { (_: URLSessionTask, _: Int64, _: Int64, _: Int64) -> Void in }
        // swiftlint:disable:next line_length
        let dowbloadCompletion: ((URLSessionDownloadTask, Int64, Int64, Int64) -> Void) = { (_: URLSessionDownloadTask, _: Int64, _: Int64, _: Int64) -> Void in }

        // Add tasks
        Parse.sessionDelegate.taskCallbackQueues[task] = DispatchQueue.main
        XCTAssertEqual(Parse.sessionDelegate.taskCallbackQueues.count, 1)
        Parse.sessionDelegate.streamDelegates[task] = .init(data: .init())
        XCTAssertEqual(Parse.sessionDelegate.streamDelegates.count, 1)
        Parse.sessionDelegate.uploadDelegates[task] = uploadCompletion
        XCTAssertEqual(Parse.sessionDelegate.uploadDelegates.count, 1)
        Parse.sessionDelegate.downloadDelegates[dowloadTask] = dowbloadCompletion
        XCTAssertEqual(Parse.sessionDelegate.downloadDelegates.count, 1)

        // Remove tasks
        Parse.sessionDelegate.taskCallbackQueues.removeValue(forKey: task)
        XCTAssertEqual(Parse.sessionDelegate.taskCallbackQueues.count, 0)
        Parse.sessionDelegate.streamDelegates.removeValue(forKey: task)
        XCTAssertEqual(Parse.sessionDelegate.streamDelegates.count, 0)
        Parse.sessionDelegate.uploadDelegates.removeValue(forKey: task)
        XCTAssertEqual(Parse.sessionDelegate.uploadDelegates.count, 0)
        Parse.sessionDelegate.downloadDelegates.removeValue(forKey: dowloadTask)
        XCTAssertEqual(Parse.sessionDelegate.downloadDelegates.count, 0)
    }

    func testParseURLSessionDelegateUpload() throws {
        // swiftlint:disable:next line_length
        let downloadTask = URLSession.shared.downloadTask(with: .init(fileURLWithPath: "http://localhost:1337/1/files/applicationId/d3a37aed0672a024595b766f97133615_logo.svg"))
        let task = downloadTask as URLSessionTask
        let queue = DispatchQueue.global(qos: .utility)

        let expectation1 = XCTestExpectation(description: "Call delegate 1")
        let expectation2 = XCTestExpectation(description: "Call delegate 2")

        // swiftlint:disable:next line_length
        let uploadCompletion: ((URLSessionTask, Int64, Int64, Int64) -> Void) = { (_: URLSessionTask, _: Int64, sent: Int64, total: Int64) -> Void in
            if sent < total {
                let uploadCount = Parse.sessionDelegate.uploadDelegates.count
                let taskCount = Parse.sessionDelegate.taskCallbackQueues.count
                XCTAssertEqual(uploadCount, 1)
                XCTAssertEqual(taskCount, 1)
                expectation1.fulfill()
                Parse.sessionDelegate.urlSession(URLSession.parse, task: task, didCompleteWithError: nil)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    let uploadCount = Parse.sessionDelegate.uploadDelegates.count
                    let taskCount = Parse.sessionDelegate.taskCallbackQueues.count
                    XCTAssertEqual(uploadCount, 0)
                    XCTAssertEqual(taskCount, 0)
                    expectation2.fulfill()
                }
            }
        }

        // Add tasks
        Parse.sessionDelegate.uploadDelegates[task] = uploadCompletion
        Parse.sessionDelegate.taskCallbackQueues[task] = queue

        Parse.sessionDelegate.urlSession(URLSession.parse,
                                              task: task,
                                              didSendBodyData: 0,
                                              totalBytesSent: 0,
                                              totalBytesExpectedToSend: 10)
        wait(for: [expectation1, expectation2], timeout: 20.0)
    }

    func testParseURLSessionDelegateDownload() throws {
        // swiftlint:disable:next line_length
        let downloadTask = URLSession.shared.downloadTask(with: .init(fileURLWithPath: "http://localhost:1337/1/files/applicationId/d3a37aed0672a024595b766f97133615_logo.svg"))
        let task = downloadTask as URLSessionTask
        let queue = DispatchQueue.global(qos: .utility)
        guard let fileManager = ParseFileManager(),
              let filePath = fileManager.dataItemPathForPathComponent("test.txt") else {
            XCTFail("Should have unwrapped")
            return
        }

        let expectation1 = XCTestExpectation(description: "Call delegate 1")
        let expectation2 = XCTestExpectation(description: "Call delegate 2")

        // swiftlint:disable:next line_length
        let downloadCompletion: ((URLSessionDownloadTask, Int64, Int64, Int64) -> Void) = { (_: URLSessionDownloadTask, _: Int64, sent: Int64, total: Int64) -> Void in
            if sent < total {
                let downloadCount = Parse.sessionDelegate.downloadDelegates.count
                let taskCount = Parse.sessionDelegate.taskCallbackQueues.count
                XCTAssertEqual(downloadCount, 1)
                XCTAssertEqual(taskCount, 1)
                expectation1.fulfill()
                Parse.sessionDelegate.urlSession(URLSession.parse,
                                                      downloadTask: downloadTask,
                                                      didFinishDownloadingTo: filePath)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    let downloadCount = Parse.sessionDelegate.downloadDelegates.count
                    let taskCount = Parse.sessionDelegate.taskCallbackQueues.count
                    XCTAssertEqual(downloadCount, 0)
                    XCTAssertEqual(taskCount, 0)
                    expectation2.fulfill()
                }
            }
        }

        // Add tasks
        Parse.sessionDelegate.downloadDelegates[downloadTask] = downloadCompletion
        Parse.sessionDelegate.taskCallbackQueues[task] = queue

        Parse.sessionDelegate.urlSession(URLSession.parse,
                                              downloadTask: downloadTask,
                                              didWriteData: 0,
                                              totalBytesWritten: 0,
                                              totalBytesExpectedToWrite: 10)
        wait(for: [expectation1, expectation2], timeout: 20.0)
    }

    func testParseURLSessionDelegateStream() throws {
        // swiftlint:disable:next line_length
        let downloadTask = URLSession.shared.downloadTask(with: .init(fileURLWithPath: "http://localhost:1337/1/files/applicationId/d3a37aed0672a024595b766f97133615_logo.svg"))
        let task = downloadTask as URLSessionTask
        let queue = DispatchQueue.global(qos: .utility)

        let expectation1 = XCTestExpectation(description: "Call delegate 1")
        let expectation2 = XCTestExpectation(description: "Call delegate 2")

        let streamCompletion: ((InputStream?) -> Void) = { (_: InputStream?) -> Void in
            let streamCount = Parse.sessionDelegate.streamDelegates.count
            let taskCount = Parse.sessionDelegate.taskCallbackQueues.count
            XCTAssertEqual(streamCount, 1)
            XCTAssertEqual(taskCount, 1)
            expectation1.fulfill()
            Parse.sessionDelegate.urlSession(URLSession.parse, task: task, didCompleteWithError: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                let streamCount = Parse.sessionDelegate.streamDelegates.count
                let taskCount = Parse.sessionDelegate.taskCallbackQueues.count
                XCTAssertEqual(streamCount, 0)
                XCTAssertEqual(taskCount, 0)
                expectation2.fulfill()
            }
        }

        // Add tasks
        Parse.sessionDelegate.streamDelegates[task] = .init(data: .init())
        Parse.sessionDelegate.taskCallbackQueues[task] = queue

        Parse.sessionDelegate.urlSession(URLSession.parse, task: task, needNewBodyStream: streamCompletion)
        wait(for: [expectation1, expectation2], timeout: 20.0)
    }
    #endif

    #if !os(Linux) && !os(Android) && !os(Windows)

    // URL Mocker is not able to mock this in linux and tests fail, so do not run.
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

        // Remove URL mocker so we can check cache
        MockURLProtocol.removeAll()
        let fetchedFileCached = try parseFile.fetch(options: [.cachePolicy(.returnCacheDataDontLoad)])
        XCTAssertEqual(fetchedFileCached, fetchedFile)
    }

    func testFetchFileLoadFromRemote() throws {
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

        let fetchedFile = try parseFile.fetch(options: [.cachePolicy(.reloadIgnoringLocalAndRemoteCacheData)])
        XCTAssertEqual(fetchedFile.name, response.name)
        XCTAssertEqual(fetchedFile.url, response.url)
        XCTAssertNotNil(fetchedFile.localURL)

        // Remove URL mocker so we can check cache
        MockURLProtocol.removeAll()
        let fetchedFileCached = try parseFile.fetch(options: [.cachePolicy(.returnCacheDataDontLoad)])
        XCTAssertEqual(fetchedFileCached, fetchedFile)
    }

    func testFetchFileLoadFromCacheNoCache() throws {
        // swiftlint:disable:next line_length
        guard let parseFileURL = URL(string: "http://localhost:1337/1/files/applicationId/d3a37aed0672a024595b766f97133615_logo.svg") else {
            XCTFail("Should create URL")
            return
        }
        var parseFile = ParseFile(name: "d3a37aed0672a024595b766f97133615_logo.svg", cloudURL: parseFileURL)
        parseFile.url = parseFileURL

        do {
            _ = try parseFile.fetch(options: [.cachePolicy(.returnCacheDataDontLoad)])
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(parseError.code, .unsavedFileFailure)
        }
    }

    func testFetchFileWithDirectoryInName() throws {
        // swiftlint:disable:next line_length
        guard let parseFileURL = URL(string: "http://localhost:1337/1/files/applicationId/d3a37aed0672a024595b766f97133615_logo.svg") else {
            XCTFail("Should create URL")
            return
        }
        var parseFile = ParseFile(name: "myFolder/d3a37aed0672a024595b766f97133615_logo.svg", cloudURL: parseFileURL)
        parseFile.url = parseFileURL

        let response = FileUploadResponse(name: "myFolder/d3a37aed0672a024595b766f97133615_logo.svg",
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
        guard let localURL = fetchedFile.localURL else {
            XCTFail("Should have unwrapped")
            return
        }
        XCTAssertFalse(localURL.pathComponents.contains("myFolder"))

        // Remove URL mocker so we can check cache
        MockURLProtocol.removeAll()
        let fetchedFileCached = try parseFile.fetch(options: [.cachePolicy(.returnCacheDataDontLoad)])
        XCTAssertEqual(fetchedFileCached, fetchedFile)
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

        // Remove URL mocker so we can check cache
        MockURLProtocol.removeAll()
        // swiftlint:disable:next line_length
        let fetchedFileCached = try parseFile.fetch(options: [.cachePolicy(.returnCacheDataDontLoad)]) { (_, _, totalDownloaded, totalExpected) in
            let currentProgess = Double(totalDownloaded)/Double(totalExpected) * 100
            XCTAssertGreaterThan(currentProgess, -1)
        }
        XCTAssertEqual(fetchedFileCached, fetchedFile)
    }

    func testFetchFileProgressLoadFromRemote() throws {
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
        // swiftlint:disable:next line_length
        let fetchedFile = try parseFile.fetch(options: [.cachePolicy(.reloadIgnoringLocalAndRemoteCacheData)]) { (_, _, totalDownloaded, totalExpected) in
            let currentProgess = Double(totalDownloaded)/Double(totalExpected) * 100
            XCTAssertGreaterThan(currentProgess, -1)
        }
        XCTAssertEqual(fetchedFile.name, response.name)
        XCTAssertEqual(fetchedFile.url, response.url)
        XCTAssertNotNil(fetchedFile.localURL)

        // Remove URL mocker so we can check cache
        MockURLProtocol.removeAll()
        // swiftlint:disable:next line_length
        let fetchedFileCached = try parseFile.fetch(options: [.cachePolicy(.returnCacheDataDontLoad)]) { (_, _, totalDownloaded, totalExpected) in
            let currentProgess = Double(totalDownloaded)/Double(totalExpected) * 100
            XCTAssertGreaterThan(currentProgess, -1)
        }
        XCTAssertEqual(fetchedFileCached, fetchedFile)
    }

    func testFetchFileProgressFromCacheNoCache() throws {
        // swiftlint:disable:next line_length
        guard let parseFileURL = URL(string: "http://localhost:1337/1/files/applicationId/d3a37aed0672a024595b766f97133615_logo.svg") else {
            XCTFail("Should create URL")
            return
        }
        var parseFile = ParseFile(name: "d3a37aed0672a024595b766f97133615_logo.svg", cloudURL: parseFileURL)
        parseFile.url = parseFileURL

        do {
            // swiftlint:disable:next line_length
            _ = try parseFile.fetch(options: [.cachePolicy(.returnCacheDataDontLoad)]) { (_, _, totalDownloaded, totalExpected) in
                let currentProgess = Double(totalDownloaded)/Double(totalExpected) * 100
                XCTAssertGreaterThan(currentProgess, -1)
            }
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(parseError.code, .unsavedFileFailure)
        }
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
        parseFile.delete(options: [.usePrimaryKey]) { result in

            if case let .failure(error) = result {
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testDeleteFileAysncError() throws {
        // swiftlint:disable:next line_length
        guard let parseFileURL = URL(string: "http://localhost:1337/1/files/applicationId/1b0683d529463e173cbf8046d7d9a613_logo.svg") else {
            XCTFail("Should create URL")
            return
        }
        var parseFile = ParseFile(name: "1b0683d529463e173cbf8046d7d9a613_logo.svg", cloudURL: parseFileURL)
        parseFile.url = parseFileURL

        let response = ParseError(code: .fileTooLarge, message: "Too large.")
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
        parseFile.delete(options: [.usePrimaryKey]) { result in

            if case .success = result {
                XCTFail("Should have failed with error")
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
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

        try parseFile.delete(options: [.usePrimaryKey])
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
    #endif
} // swiftlint:disable:this file_length
