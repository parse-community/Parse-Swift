//
//  ParseFileManagerTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 12/26/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

struct FileUploadResponse: Codable {
    let name: String
    let url: URL
}

class ParseFileManagerTests: XCTestCase {

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

        guard let fileManager = ParseFileManager(),
              let defaultDirectory = fileManager.defaultDataDirectoryPath else {
            throw ParseError(code: .unknownError, message: "Should have initialized file manage")
        }
        try fileManager.createDirectoryIfNeeded(defaultDirectory.relativePath)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        MockURLProtocol.removeAll()
        #if !os(Linux) && !os(Android) && !os(Windows)
        try KeychainStore.shared.deleteAll()
        #endif
        try ParseStorage.shared.deleteAll()

        guard let fileManager = ParseFileManager(),
              let defaultDirectoryPath = fileManager.defaultDataDirectoryPath else {
            throw ParseError(code: .unknownError, message: "Should have initialized file manage")
        }

        let expectation1 = XCTestExpectation(description: "Delete files1")
        fileManager.removeDirectoryContents(defaultDirectoryPath) { error in
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

    func testWriteData() throws {
        guard let data = "Hello World".data(using: .utf8),
              let fileManager = ParseFileManager(),
              let filePath = fileManager.dataItemPathForPathComponent("test.txt") else {
            throw ParseError(code: .unknownError, message: "Should have initialized file manage")
        }

        let expectation1 = XCTestExpectation(description: "ParseFile async")
        fileManager.writeData(data, filePath: filePath) { error in
            guard let error = error else {
                guard let readFile = try? Data(contentsOf: filePath) else {
                    XCTFail("Should have read as string")
                    return
                }
                XCTAssertEqual(readFile, data)
                expectation1.fulfill()
                return
            }
            XCTFail(error.localizedDescription)
            expectation1.fulfill()
        }

        wait(for: [expectation1], timeout: 20.0)
    }

    func testCopyItem() throws {
        let dataAsString = "Hello World"
        guard let fileManager = ParseFileManager(),
              let filePath = fileManager.dataItemPathForPathComponent("test.txt"),
              let filePath2 = fileManager.dataItemPathForPathComponent("test2.txt") else {
            throw ParseError(code: .unknownError, message: "Should have initialized file manage")
        }

        let expectation1 = XCTestExpectation(description: "ParseFile async")
        fileManager.writeString(dataAsString, filePath: filePath) { error in
            guard let error = error else {
                guard let readFile = try? String(contentsOf: filePath) else {
                    XCTFail("Should have read as string")
                    return
                }
                XCTAssertEqual(readFile, dataAsString)

                fileManager.copyItem(filePath, toPath: filePath2) { _ in
                    guard let readFile = try? String(contentsOf: filePath),
                          let readFile2 = try? String(contentsOf: filePath2) else {
                        XCTFail("Should have read as string")
                        return
                    }

                    XCTAssertEqual(readFile, dataAsString)
                    XCTAssertEqual(readFile2, dataAsString)
                    expectation1.fulfill()
                }
                return
            }
            XCTFail(error.localizedDescription)
            expectation1.fulfill()
        }

        wait(for: [expectation1], timeout: 20.0)
    }

    func testMoveItem() throws {
        let dataAsString = "Hello World"
        guard let fileManager = ParseFileManager(),
              let filePath = fileManager.dataItemPathForPathComponent("test.txt"),
              let filePath2 = fileManager.dataItemPathForPathComponent("test2.txt") else {
            throw ParseError(code: .unknownError, message: "Should have initialized file manage")
        }

        let expectation1 = XCTestExpectation(description: "ParseFile async")
        fileManager.writeString(dataAsString, filePath: filePath) { error in
            guard let error = error else {
                guard let readFile = try? String(contentsOf: filePath) else {
                    XCTFail("Should have read as string")
                    return
                }
                XCTAssertEqual(readFile, dataAsString)

                fileManager.moveItem(filePath, toPath: filePath2) { _ in
                    guard let readFile2 = try? String(contentsOf: filePath2) else {
                        XCTFail("Should have read as string")
                        return
                    }
                    XCTAssertFalse(FileManager.default.fileExists(atPath: filePath.relativePath))
                    XCTAssertEqual(readFile2, dataAsString)
                    expectation1.fulfill()
                }
                return
            }
            XCTFail(error.localizedDescription)
            expectation1.fulfill()
        }

        wait(for: [expectation1], timeout: 20.0)
    }

    func testDontMoveSameItem() throws {
        let dataAsString = "Hello World"
        guard let fileManager = ParseFileManager(),
              let filePath = fileManager.dataItemPathForPathComponent("test.txt"),
              let filePath2 = fileManager.dataItemPathForPathComponent("test.txt") else {
            throw ParseError(code: .unknownError, message: "Should have initialized file manage")
        }

        let expectation1 = XCTestExpectation(description: "ParseFile async")
        fileManager.writeString(dataAsString, filePath: filePath) { error in
            guard let error = error else {
                guard let readFile = try? String(contentsOf: filePath) else {
                    XCTFail("Should have read as string")
                    return
                }
                XCTAssertEqual(readFile, dataAsString)

                fileManager.moveItem(filePath, toPath: filePath2) { _ in
                    guard let readFile2 = try? String(contentsOf: filePath2) else {
                        XCTFail("Should have read as string")
                        return
                    }
                    XCTAssertTrue(FileManager.default.fileExists(atPath: filePath2.relativePath))
                    XCTAssertEqual(readFile2, dataAsString)
                    expectation1.fulfill()
                }
                return
            }
            XCTFail(error.localizedDescription)
            expectation1.fulfill()
        }

        wait(for: [expectation1], timeout: 20.0)
    }

    func testMoveContentsOfDirectory() throws {
        let dataAsString = "Hello World"
        guard let fileManager = ParseFileManager(),
              let defaultFilePath = fileManager.defaultDataDirectoryPath else {
            throw ParseError(code: .unknownError, message: "Should have initialized file manage")
        }

        let oldPath = defaultFilePath.appendingPathComponent("old")
        try fileManager.createDirectoryIfNeeded(oldPath.relativePath)
        let filePath = oldPath.appendingPathComponent("test.txt")
        let filePath2 = defaultFilePath.appendingPathComponent("new/")

        let expectation1 = XCTestExpectation(description: "ParseFile async")
        fileManager.writeString(dataAsString, filePath: filePath) { error in
            guard let error = error else {
                guard let readFile = try? String(contentsOf: filePath) else {
                    XCTFail("Should have read as string")
                    return
                }
                XCTAssertEqual(readFile, dataAsString)

                fileManager.moveContentsOfDirectory(oldPath, toPath: filePath2) { _ in
                    let movedFilePath = filePath2.appendingPathComponent("test.txt")
                    guard let readFile2 = try? String(contentsOf: movedFilePath) else {
                        XCTFail("Should have read as string")
                        return
                    }
                    XCTAssertFalse(FileManager.default.fileExists(atPath: filePath.relativePath))
                    XCTAssertEqual(readFile2, dataAsString)
                    expectation1.fulfill()
                }
                return
            }
            XCTFail(error.localizedDescription)
            expectation1.fulfill()
        }

        wait(for: [expectation1], timeout: 20.0)
    }
}
