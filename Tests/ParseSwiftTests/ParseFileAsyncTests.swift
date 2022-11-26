//
//  ParseFileAsyncTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 9/28/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if compiler(>=5.5.2) && canImport(_Concurrency)
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
@testable import ParseSwift

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
        #if !os(Linux) && !os(Android) && !os(Windows)
        try KeychainStore.shared.deleteAll()
        #endif
        try ParseStorage.shared.deleteAll()

        guard let fileManager = ParseFileManager() else {
            throw ParseError(code: .otherCause, message: "Should have initialized file manager")
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

    #if !os(Linux) && !os(Android) && !os(Windows)
    //URL Mocker is not able to mock this in linux and tests fail, so do not run.
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

        // Remove URL mocker so we can check cache
        MockURLProtocol.removeAll()
        let fetchedFileCached = try await parseFile.fetch(options: [.cachePolicy(.returnCacheDataDontLoad)])
        XCTAssertEqual(fetchedFileCached, fetched)
    }

    @MainActor
    func testFetchLoadFromRemote() async throws {

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

        let fetched = try await parseFile.fetch(options: [.cachePolicy(.reloadIgnoringLocalAndRemoteCacheData)])
        XCTAssertEqual(fetched.name, response.name)
        XCTAssertEqual(fetched.url, response.url)
        XCTAssertNotNil(fetched.localURL)

        // Remove URL mocker so we can check cache
        MockURLProtocol.removeAll()
        let fetchedFileCached = try await parseFile.fetch(options: [.cachePolicy(.returnCacheDataDontLoad)])
        XCTAssertEqual(fetchedFileCached, fetched)
    }

    @MainActor
    func testFetchLoadFromCacheNoCache() async throws {

        // swiftlint:disable:next line_length
        guard let parseFileURL = URL(string: "http://localhost:1337/1/files/applicationId/d3a37aed0672a024595b766f97133615_logo.svg") else {
            XCTFail("Should create URL")
            return
        }
        var parseFile = ParseFile(name: "d3a37aed0672a024595b766f97133615_logo.svg", cloudURL: parseFileURL)
        parseFile.url = parseFileURL

        do {
            _ = try await parseFile.fetch(options: [.cachePolicy(.returnCacheDataDontLoad)])
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(parseError.code, .unsavedFileFailure)
        }
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
    #endif

    @MainActor
    func testSave() async throws {

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

        let fetched = try await parseFile.save()
        XCTAssertEqual(fetched.name, response.name)
        XCTAssertEqual(fetched.url, response.url)
    }

    @MainActor
    func testSaveFileProgress() async throws {

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

        _ = try await parseFile.delete(options: [.usePrimaryKey])
    }

    @MainActor
    func testDeleteError () async throws {
        // swiftlint:disable:next line_length
        guard let parseFileURL = URL(string: "http://localhost:1337/1/files/applicationId/d3a37aed0672a024595b766f97133615_logo.svg") else {
            XCTFail("Should create URL")
            return
        }
        var parseFile = ParseFile(name: "d3a37aed0672a024595b766f97133615_logo.svg", cloudURL: parseFileURL)
        parseFile.url = parseFileURL

        let serverResponse = ParseError(code: .fileDeleteFailure, message: "not found")

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
            _ = try await parseFile.delete(options: [.usePrimaryKey])
            XCTFail("Should have thrown error")
        } catch {

            guard let error = error as? ParseError else {
                XCTFail("Should be ParseError")
                return
            }
            XCTAssertEqual(error.message, serverResponse.message)
        }
    }

    @MainActor
    func testParseURLSessionDelegates() async throws {
        // swiftlint:disable:next line_length
        let downloadTask = URLSession.shared.downloadTask(with: .init(fileURLWithPath: "http://localhost:1337/1/files/applicationId/d3a37aed0672a024595b766f97133615_logo.svg"))
        let task = downloadTask as URLSessionTask
        // swiftlint:disable:next line_length
        let uploadCompletion: ((URLSessionTask, Int64, Int64, Int64) -> Void) = { (_: URLSessionTask, _: Int64, _: Int64, _: Int64) -> Void in }
        // swiftlint:disable:next line_length
        let downloadCompletion: ((URLSessionDownloadTask, Int64, Int64, Int64) -> Void) = { (_: URLSessionDownloadTask, _: Int64, _: Int64, _: Int64) -> Void in }

        // Add tasks
        Parse.sessionDelegate.streamDelegates[task] = .init(data: .init())
        XCTAssertEqual(Parse.sessionDelegate.streamDelegates.count, 1)
        await Parse.sessionDelegate.delegates.updateTask(task, queue: DispatchQueue.main)
        let taskCount = await Parse.sessionDelegate.delegates.taskCallbackQueues.count
        XCTAssertEqual(taskCount, 1)
        await Parse.sessionDelegate.delegates.updateUpload(task, callback: uploadCompletion)
        let uploadCount = await Parse.sessionDelegate.delegates.uploadDelegates.count
        XCTAssertEqual(uploadCount, 1)
        await Parse.sessionDelegate.delegates.updateDownload(downloadTask, callback: downloadCompletion)
        let downloadCount = await Parse.sessionDelegate.delegates.downloadDelegates.count
        XCTAssertEqual(downloadCount, 1)

        // Remove tasks
        Parse.sessionDelegate.streamDelegates.removeValue(forKey: task)
        XCTAssertEqual(Parse.sessionDelegate.streamDelegates.count, 0)
        await Parse.sessionDelegate.delegates.removeTask(task)
        let taskCount2 = await Parse.sessionDelegate.delegates.taskCallbackQueues.count
        XCTAssertEqual(taskCount2, 0)
        await Parse.sessionDelegate.delegates.removeUpload(task)
        let uploadCount2 = await Parse.sessionDelegate.delegates.uploadDelegates.count
        XCTAssertEqual(uploadCount2, 0)
        await Parse.sessionDelegate.delegates.removeDownload(downloadTask)
        let downloadCount2 = await Parse.sessionDelegate.delegates.downloadDelegates.count
        XCTAssertEqual(downloadCount2, 0)
    }

    #if !os(iOS)
    func testParseURLSessionDelegateUpload() async throws {
        // swiftlint:disable:next line_length
        let downloadTask = URLSession.shared.downloadTask(with: .init(fileURLWithPath: "http://localhost:1337/1/files/applicationId/d3a37aed0672a024595b766f97133615_logo.svg"))
        let task = downloadTask as URLSessionTask
        let queue = DispatchQueue.global(qos: .utility)

        let expectation1 = XCTestExpectation(description: "Call delegate 1")
        let expectation2 = XCTestExpectation(description: "Call delegate 2")

        // swiftlint:disable:next line_length
        let uploadCompletion: ((URLSessionTask, Int64, Int64, Int64) -> Void) = { (_: URLSessionTask, _: Int64, sent: Int64, total: Int64) -> Void in
            if sent < total {
                Task {
                    let uploadCount = await Parse.sessionDelegate.delegates.uploadDelegates.count
                    let taskCount = await Parse.sessionDelegate.delegates.taskCallbackQueues.count
                    Parse.sessionDelegate.urlSession(URLSession.parse,
                                                          task: task,
                                                          didCompleteWithError: nil)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                        XCTAssertEqual(uploadCount, 1)
                        XCTAssertEqual(taskCount, 1)
                        expectation1.fulfill()

                        Task {
                            let uploadCount = await Parse.sessionDelegate.delegates.uploadDelegates.count
                            let taskCount = await Parse.sessionDelegate.delegates.taskCallbackQueues.count
                            XCTAssertEqual(uploadCount, 0)
                            XCTAssertEqual(taskCount, 0)
                            expectation2.fulfill()
                        }
                    }
                }
            }
        }

        // Add tasks
        await Parse.sessionDelegate.delegates.updateUpload(task, callback: uploadCompletion)
        await Parse.sessionDelegate.delegates.updateTask(task, queue: queue)

        Parse.sessionDelegate.urlSession(URLSession.parse,
                                              task: task,
                                              didSendBodyData: 0,
                                              totalBytesSent: 0,
                                              totalBytesExpectedToSend: 10)
        wait(for: [expectation1, expectation2], timeout: 20.0)
    }

    func testParseURLSessionDelegateDownload() async throws {
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
                Task {
                    let downloadCount = await Parse.sessionDelegate.delegates.downloadDelegates.count
                    let taskCount = await Parse.sessionDelegate.delegates.taskCallbackQueues.count
                    Parse.sessionDelegate.urlSession(URLSession.parse,
                                                          downloadTask: downloadTask,
                                                          didFinishDownloadingTo: filePath)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                        XCTAssertEqual(downloadCount, 1)
                        XCTAssertEqual(taskCount, 1)
                        expectation1.fulfill()

                        Task {
                            let downloadCount = await Parse.sessionDelegate.delegates.downloadDelegates.count
                            let taskCount = await Parse.sessionDelegate.delegates.taskCallbackQueues.count
                            XCTAssertEqual(downloadCount, 0)
                            XCTAssertEqual(taskCount, 0)
                            expectation2.fulfill()
                        }
                    }
                }
            }
        }

        // Add tasks
        await Parse.sessionDelegate.delegates.updateDownload(downloadTask, callback: downloadCompletion)
        await Parse.sessionDelegate.delegates.updateTask(task, queue: queue)

        Parse.sessionDelegate.urlSession(URLSession.parse,
                                              downloadTask: downloadTask,
                                              didWriteData: 0,
                                              totalBytesWritten: 0,
                                              totalBytesExpectedToWrite: 10)
        wait(for: [expectation1, expectation2], timeout: 20.0)
    }

    func testParseURLSessionDelegateStream() async throws {
        // swiftlint:disable:next line_length
        let downloadTask = URLSession.shared.downloadTask(with: .init(fileURLWithPath: "http://localhost:1337/1/files/applicationId/d3a37aed0672a024595b766f97133615_logo.svg"))
        let task = downloadTask as URLSessionTask
        let queue = DispatchQueue.global(qos: .utility)

        let expectation1 = XCTestExpectation(description: "Call delegate 1")
        let expectation2 = XCTestExpectation(description: "Call delegate 2")

        let streamCompletion: ((InputStream?) -> Void) = { (_: InputStream?) -> Void in
            Task {
                let streamCount = Parse.sessionDelegate.streamDelegates.count
                let taskCount = await Parse.sessionDelegate.delegates.taskCallbackQueues.count
                Parse.sessionDelegate.urlSession(URLSession.parse, task: task, didCompleteWithError: nil)

                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    XCTAssertEqual(streamCount, 1)
                    XCTAssertEqual(taskCount, 1)
                    expectation1.fulfill()

                    Task {
                        let streamCount = Parse.sessionDelegate.streamDelegates.count
                        let taskCount = await Parse.sessionDelegate.delegates.taskCallbackQueues.count
                        XCTAssertEqual(streamCount, 0)
                        XCTAssertEqual(taskCount, 0)
                        expectation2.fulfill()
                    }
                }
            }
        }

        // Add tasks
        Parse.sessionDelegate.streamDelegates[task] = .init(data: .init())
        await Parse.sessionDelegate.delegates.updateTask(task, queue: queue)

        Parse.sessionDelegate.urlSession(URLSession.parse, task: task, needNewBodyStream: streamCompletion)
        wait(for: [expectation1, expectation2], timeout: 20.0)
    }
    #endif
}
#endif
