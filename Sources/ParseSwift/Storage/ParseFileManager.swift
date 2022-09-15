//
//  ParseFileManager.swift
//  ParseSwift
//
//  Created by Corey Baker on 12/20/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation

/// Manages Parse files and directories.
public struct ParseFileManager {

    private var defaultDirectoryAttributes: [FileAttributeKey: Any]? {
        #if os(macOS) || os(Linux) || os(Android) || os(Windows)
        return nil
        #else
        return [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]
        #endif
    }

    private var defaultDataWritingOptions: Data.WritingOptions {
        var options = Data.WritingOptions.atomic
        #if !os(macOS) && !os(Linux) && !os(Android) && !os(Windows)
            options.insert(.completeFileProtectionUntilFirstUserAuthentication)
        #endif
        return options
    }

    private var localSandBoxDataDirectoryPath: URL? {
        #if os(macOS) || os(Linux) || os(Android) || os(Windows)
        return self.defaultDataDirectoryPath
        #else
        // swiftlint:disable:next line_length
        let directoryPath = "\(NSHomeDirectory())/\(ParseConstants.fileManagementLibraryDirectory)\(ParseConstants.fileManagementPrivateDocumentsDirectory)\(ParseConstants.fileManagementDirectory)"
        guard (try? createDirectoryIfNeeded(directoryPath)) != nil else {
            return nil
        }
        return URL(fileURLWithPath: directoryPath, isDirectory: true)
        #endif
    }

    private let synchronizationQueue = DispatchQueue(label: "com.parse.file",
                                                     qos: .default,
                                                     attributes: .concurrent,
                                                     autoreleaseFrequency: .inherit,
                                                     target: nil)

    private let applicationIdentifier: String
    private let applicationGroupIdentifer: String?

    /// The default directory for storing Parse files.
    public var defaultDataDirectoryPath: URL? {
        #if os(macOS) || os(Linux) || os(Android) || os(Windows)
        var directoryPath: String!
        let paths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
        guard let directory = paths.first else {
            return nil
        }
        directoryPath = directory
        directoryPath += "/\(ParseConstants.fileManagementDirectory)\(applicationIdentifier)"
        return URL(fileURLWithPath: directoryPath, isDirectory: true)
        #else
        if let groupIdentifier = applicationGroupIdentifer {
            guard var directory = FileManager
                    .default
                    .containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier) else {
                return nil
            }
            directory.appendPathComponent(ParseConstants.fileManagementDirectory)
            directory.appendPathComponent(applicationIdentifier)
            return directory
        } else {
            return self.localSandBoxDataDirectoryPath
        }
        #endif
    }

    /// Creates an instance of `ParseFileManager`.
    /// - returns: If an instance cannot be created, nil is returned.
    public init?() {
        #if os(Linux) || os(Android) || os(Windows)
        let applicationId = Parse.configuration.applicationId
        applicationIdentifier = "\(ParseConstants.bundlePrefix).\(applicationId)"
        #else
        if let identifier = Bundle.main.bundleIdentifier {
            applicationIdentifier = identifier
        } else {
            return nil
        }
        #endif

        applicationGroupIdentifer = nil
    }
}

// MARK: Helper Methods (Internal)
extension ParseFileManager {
    func dataItemPathForPathComponent(_ component: String) -> URL? {
        guard var path = self.defaultDataDirectoryPath else {
            return nil
        }
        path.appendPathComponent(component)
        return path
    }

    func createDirectoryIfNeeded(_ path: String) throws {
        if !FileManager.default.fileExists(atPath: path) {
            try FileManager.default.createDirectory(atPath: path,
                                                    withIntermediateDirectories: true,
                                                    attributes: defaultDirectoryAttributes)
        }
    }

    func writeString(_ string: String, filePath: URL, completion: @escaping(Error?) -> Void) {
        synchronizationQueue.async {
            do {
                guard let data = string.data(using: .utf8) else {
                    completion(ParseError(code: .unknownError, message: "Could not convert string to utf8"))
                    return
                }
                try data.write(to: filePath, options: self.defaultDataWritingOptions)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }

    func writeData(_ data: Data, filePath: URL, completion: @escaping(Error?) -> Void) {
        synchronizationQueue.async {
            do {
                try data.write(to: filePath, options: self.defaultDataWritingOptions)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }

    func copyItem(_ fromPath: URL, toPath: URL, completion: @escaping(Error?) -> Void) {
        synchronizationQueue.async {
            do {
                try FileManager.default.copyItem(at: fromPath, to: toPath)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }

    func moveItem(_ fromPath: URL, toPath: URL, completion: @escaping(Error?) -> Void) {
        synchronizationQueue.async {
            if fromPath != toPath {
                do {
                    try FileManager.default.moveItem(at: fromPath, to: toPath)
                    completion(nil)
                } catch {
                    completion(error)
                }
            } else {
                completion(nil)
            }
        }
    }

    func moveContentsOfDirectory(_ fromPath: URL, toPath: URL, completion: @escaping(Error?) -> Void) {
        synchronizationQueue.async {
            do {
                if fromPath == toPath {
                    completion(nil)
                    return
                }

                try self.createDirectoryIfNeeded(toPath.path)
                let contents = try FileManager.default.contentsOfDirectory(atPath: fromPath.path)
                if contents.count == 0 {
                    completion(nil)
                    return
                }
                try contents.forEach {
                    let fromFilePath = fromPath.appendingPathComponent($0)
                    let toFilePath = toPath.appendingPathComponent($0)
                    try FileManager.default.moveItem(at: fromFilePath, to: toFilePath)
                }
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }

    func removeDirectoryContents(_ path: URL, completion: @escaping(Error?) -> Void) {
        synchronizationQueue.async {
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: path.path)
                if contents.count == 0 {
                    completion(nil)
                    return
                }
                try contents.forEach {
                    let filePath = path.appendingPathComponent($0)
                    try FileManager.default.removeItem(at: filePath)
                }
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
}

// MARK: Helper Methods (External)
public extension ParseFileManager {

    /**
     The download directory for all `ParseFile`'s.
     - returns: The download directory.
     - throws: An error of type `ParseError`.
     */
    static func downloadDirectory() throws -> URL {
        guard let fileManager = ParseFileManager(),
              let defaultDirectoryPath = fileManager.defaultDataDirectoryPath else {
            throw ParseError(code: .unknownError, message: "Cannot create ParseFileManager")
        }
        return defaultDirectoryPath
            .appendingPathComponent(ParseConstants.fileDownloadsDirectory,
                                    isDirectory: true)
    }

    /**
     Check if a file exists in the Swift SDK download directory.
     - parameter name: The name of the file to check.
     - returns: The location of the file.
     - throws: An error of type `ParseError`.
     */
    static func fileExists(_ name: String) throws -> URL {
        let fileName = URL(fileURLWithPath: name).lastPathComponent
        let fileLocation = try downloadDirectory().appendingPathComponent(fileName).relativePath
        guard FileManager.default.fileExists(atPath: fileLocation) else {
            throw ParseError(code: .unknownError, message: "File does not exist")
        }
        return URL(fileURLWithPath: fileLocation, isDirectory: false)
    }

    /**
     Check if a `ParseFile` exists in the Swift SDK download directory.
     - parameter file: The `ParseFile` to check.
     - returns: The location of the file.
     - throws: An error of type `ParseError`.
     */
    static func fileExists(_ file: ParseFile) throws -> URL {
        try fileExists(file.name)
    }
}
