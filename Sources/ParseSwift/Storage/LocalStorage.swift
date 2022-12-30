//
//  LocalStorage.swift
//  
//
//  Created by Damian Van de Kauter on 03/12/2022.
//

import Foundation

public extension ParseObject {

    /**
     Fetch all local objects.
     
     - returns: If objects are more recent on the database, it will replace the local objects and return them.
     
     - note: You will need to run this on every `ParseObject` that needs to fetch it's local objects
     after creating offline objects.
     */
    @discardableResult static func fetchLocalStore<T: ParseObject>(_ type: T.Type) async throws -> [T]? {
        return try await LocalStorage.fetchLocalObjects(type)
    }
}

internal struct LocalStorage {
    static let fileManager = FileManager.default

    static func save<T: ParseObject>(_ object: T,
                                     queryIdentifier: String?) throws {
        let objectData = try ParseCoding.jsonEncoder().encode(object)

        guard let objectId = object.objectId else {
            throw ParseError(code: .missingObjectId, message: "Object has no valid objectId")
        }

        let objectsDirectoryPath = try ParseFileManager.objectsDirectory(className: object.className)
        let objectPath = objectsDirectoryPath.appendingPathComponent(objectId)

        if fileManager.fileExists(atPath: objectPath.path) {
            try objectData.write(to: objectPath)
        } else {
            fileManager.createFile(atPath: objectPath.path, contents: objectData, attributes: nil)
        }

        if let queryIdentifier = queryIdentifier {
            try self.saveQueryObjects([object], queryIdentifier: queryIdentifier)
        }
    }

    static func saveAll<T: ParseObject>(_ objects: [T],
                                        queryIdentifier: String?) throws {
        var successObjects: [T] = []
        for object in objects {
            let objectData = try ParseCoding.jsonEncoder().encode(object)
            guard let objectId = object.objectId else {
                throw ParseError(code: .missingObjectId, message: "Object has no valid objectId")
            }

            let objectsDirectoryPath = try ParseFileManager.objectsDirectory(className: object.className)
            let objectPath = objectsDirectoryPath.appendingPathComponent(objectId)

            if fileManager.fileExists(atPath: objectPath.path) {
                try objectData.write(to: objectPath)
            } else {
                fileManager.createFile(atPath: objectPath.path, contents: objectData, attributes: nil)
            }

            successObjects.append(object)
        }

        if let queryIdentifier = queryIdentifier {
            try self.saveQueryObjects(successObjects, queryIdentifier: queryIdentifier)
        }
    }

    static func get<U: Decodable>(_ type: U.Type,
                                  queryIdentifier: String) throws -> U? {
        guard let queryObjects = try getQueryObjects()[queryIdentifier],
                let queryObject = queryObjects.first else { return nil }

        let objectsDirectoryPath = try ParseFileManager.objectsDirectory(className: queryObject.className)
        let objectPath = objectsDirectoryPath.appendingPathComponent(queryObject.objectId)

        let objectData = try Data(contentsOf: objectPath)

        return try ParseCoding.jsonDecoder().decode(U.self, from: objectData)
    }

    static func getAll<U: Decodable>(_ type: U.Type,
                                     queryIdentifier: String) throws -> [U]? {
        guard let queryObjects = try getQueryObjects()[queryIdentifier] else { return nil }

        var allObjects: [U] = []
        for queryObject in queryObjects {
            let objectsDirectoryPath = try ParseFileManager.objectsDirectory(className: queryObject.className)
            let objectPath = objectsDirectoryPath.appendingPathComponent(queryObject.objectId)

            let objectData = try Data(contentsOf: objectPath)
            if let object = try? ParseCoding.jsonDecoder().decode(U.self, from: objectData) {
                allObjects.append(object)
            }
        }

        return (allObjects.isEmpty ? nil : allObjects)
    }

    static fileprivate func saveFetchObjects<T: ParseObject>(_ objects: [T],
                                                             method: Method) throws {
        var fetchObjects = try getFetchObjects()
        fetchObjects.append(contentsOf: try objects.map({ try FetchObject($0, method: method) }))
        fetchObjects = fetchObjects.uniqueObjectsById

        try self.writeFetchObjects(fetchObjects)
    }

    static fileprivate func removeFetchObjects<T: ParseObject>(_ objects: [T]) throws {
        var fetchObjects = try getFetchObjects()
        let objectIds = objects.compactMap({ $0.objectId })
        fetchObjects.removeAll(where: { removableObject in
            objectIds.contains(where: { currentObjectId in
                removableObject.objectId == currentObjectId
            })
        })
        fetchObjects = fetchObjects.uniqueObjectsById

        try self.writeFetchObjects(fetchObjects)
    }

    static fileprivate func getFetchObjects() throws -> [FetchObject] {
        let objectsDirectoryPath = try ParseFileManager.objectsDirectory()
        let fetchObjectsPath = objectsDirectoryPath.appendingPathComponent(ParseConstants.fetchObjectsFile.hiddenFile)

        if fileManager.fileExists(atPath: fetchObjectsPath.path) {
            let jsonData = try Data(contentsOf: fetchObjectsPath)
            do {
                return try ParseCoding.jsonDecoder().decode([FetchObject].self, from: jsonData).uniqueObjectsById
            } catch {
                try fileManager.removeItem(at: fetchObjectsPath)
                return []
            }
        } else {
            return []
        }
    }

    static private func writeFetchObjects(_ fetchObjects: [FetchObject]) throws {
        let objectsDirectoryPath = try ParseFileManager.objectsDirectory()
        let fetchObjectsPath = objectsDirectoryPath.appendingPathComponent(ParseConstants.fetchObjectsFile.hiddenFile)

        if fetchObjects.isEmpty {
            try? fileManager.removeItem(at: fetchObjectsPath)
        } else {
            let jsonData = try ParseCoding.jsonEncoder().encode(fetchObjects)

            if fileManager.fileExists(atPath: fetchObjectsPath.path) {
                try jsonData.write(to: fetchObjectsPath)
            } else {
                fileManager.createFile(atPath: fetchObjectsPath.path, contents: jsonData, attributes: nil)
            }
        }
    }

    static fileprivate func saveQueryObjects<T: ParseObject>(_ objects: [T],
                                                             queryIdentifier: String) throws {
        var queryObjects = try getQueryObjects()
        queryObjects[queryIdentifier] = try objects.map({ try QueryObject($0) })

        try self.writeQueryObjects(queryObjects)
    }

    static fileprivate func getQueryObjects() throws -> [String: [QueryObject]] {
        let objectsDirectoryPath = try ParseFileManager.objectsDirectory()
        let queryObjectsPath = objectsDirectoryPath.appendingPathComponent(ParseConstants.queryObjectsFile.hiddenFile)

        if fileManager.fileExists(atPath: queryObjectsPath.path) {
            let jsonData = try Data(contentsOf: queryObjectsPath)
            do {
                return try ParseCoding.jsonDecoder().decode([String: [QueryObject]].self, from: jsonData)
            } catch {
                try fileManager.removeItem(at: queryObjectsPath)
                return [:]
            }
        } else {
            return [:]
        }
    }

    static private func writeQueryObjects(_ queryObjects: [String: [QueryObject]]) throws {
        let objectsDirectoryPath = try ParseFileManager.objectsDirectory()
        let queryObjectsPath = objectsDirectoryPath.appendingPathComponent(ParseConstants.queryObjectsFile.hiddenFile)

        if queryObjects.isEmpty {
            try? fileManager.removeItem(at: queryObjectsPath)
        } else {
            let jsonData = try ParseCoding.jsonEncoder().encode(queryObjects)

            if fileManager.fileExists(atPath: queryObjectsPath.path) {
                try jsonData.write(to: queryObjectsPath)
            } else {
                fileManager.createFile(atPath: queryObjectsPath.path, contents: jsonData, attributes: nil)
            }
        }
    }

    /**
     Fetch all local objects.
     
     - returns: If objects are more recent on the database, it will replace the local objects and return them.
     */
    @discardableResult static func fetchLocalObjects<T: ParseObject>(_ type: T.Type) async throws -> [T]? {
        let fetchObjects = try getFetchObjects()
        if fetchObjects.isEmpty {
            return nil
        }

        var saveObjects = try fetchObjects
            .filter({ $0.method == .save })
            .asParseObjects(type)
        var createObjects = try fetchObjects
            .filter({ $0.method == .create })
            .asParseObjects(type)
        var replaceObjects = try fetchObjects
            .filter({ $0.method == .replace })
            .asParseObjects(type)
        var updateObjects = try fetchObjects
            .filter({ $0.method == .update })
            .asParseObjects(type)

        var cloudObjects: [T] = []

        if Parse.configuration.offlinePolicy.enabled {
            try await self.fetchLocalStore(.save, objects: &saveObjects, cloudObjects: &cloudObjects)
        }

        if Parse.configuration.offlinePolicy.canCreate {
            if Parse.configuration.isRequiringCustomObjectIds {
                try await self.fetchLocalStore(.create, objects: &createObjects, cloudObjects: &cloudObjects)
            } else {
                assertionFailure("Enable custom objectIds")
            }
        }

        if Parse.configuration.offlinePolicy.enabled {
            try await self.fetchLocalStore(.replace, objects: &replaceObjects, cloudObjects: &cloudObjects)
        }

        if Parse.configuration.offlinePolicy.enabled {
            try await self.fetchLocalStore(.update, objects: &updateObjects, cloudObjects: &cloudObjects)
        }

        if cloudObjects.isEmpty {
            return nil
        } else {
            try self.saveAll(cloudObjects, queryIdentifier: nil)
            return cloudObjects
        }
    }

    private static func fetchLocalStore<T: ParseObject>(_ method: Method,
                                                        objects: inout [T],
                                                        cloudObjects: inout [T]) async throws {
        let queryObjects = T.query()
            .where(containedIn(key: "objectId", array: objects.map({ $0.objectId })))
            .useLocalStore(false)
        let foundObjects = try? await queryObjects.find()

        for object in objects {
            if let matchingObject = foundObjects?.first(where: { $0.objectId == object.objectId }) {
                if let objectUpdatedAt = object.updatedAt {
                    if let matchingObjectUpdatedAt = matchingObject.updatedAt {
                        if objectUpdatedAt < matchingObjectUpdatedAt {
                            objects.removeAll(where: { $0.objectId == matchingObject.objectId })
                            cloudObjects.append(matchingObject)
                        }
                    }
                } else {
                    objects.removeAll(where: { $0.objectId == matchingObject.objectId })
                    cloudObjects.append(matchingObject)
                }
            }
        }

        switch method {
        case .save:
            try await objects.saveAll(ignoringLocalStore: true)
        case .create:
            try await objects.createAll(ignoringLocalStore: true)
        case .replace:
            try await objects.replaceAll(ignoringLocalStore: true)
        case .update:
            _ = try await objects.updateAll(ignoringLocalStore: true)
        }

        try self.removeFetchObjects(objects)
    }
}

internal struct FetchObject: Codable {
    let objectId: String
    let className: String
    let updatedAt: Date
    let method: Method

    init<T: ParseObject>(_ object: T, method: Method) throws {
        guard let objectId = object.objectId else {
            throw ParseError(code: .missingObjectId, message: "Object has no valid objectId")
        }
        self.objectId = objectId
        self.className = object.className
        self.updatedAt = object.updatedAt ?? Date()
        self.method = method
    }
}

internal struct QueryObject: Codable {
    let objectId: String
    let className: String
    let queryDate: Date

    init<T: ParseObject>(_ object: T) throws {
        guard let objectId = object.objectId else {
            throw ParseError(code: .missingObjectId, message: "Object has no valid objectId")
        }
        self.objectId = objectId
        self.className = object.className
        self.queryDate = Date()
    }
}

internal extension ParseObject {

    func saveLocally(method: Method? = nil,
                     queryIdentifier: String? = nil,
                     error: Error? = nil) throws {
        if let method = method {
            switch method {
            case .save:
                if Parse.configuration.offlinePolicy.enabled {
                    if let error = error {
                        if error.hasNoInternetConnection {
                            try LocalStorage.save(self, queryIdentifier: queryIdentifier)
                            try LocalStorage.saveFetchObjects([self], method: method)
                        }
                    } else {
                        try LocalStorage.save(self, queryIdentifier: queryIdentifier)
                    }
                }
            case .create:
                if Parse.configuration.offlinePolicy.canCreate {
                    if Parse.configuration.isRequiringCustomObjectIds {
                        if let error = error {
                            if error.hasNoInternetConnection {
                                try LocalStorage.save(self, queryIdentifier: queryIdentifier)
                                try LocalStorage.saveFetchObjects([self], method: method)
                            }
                        } else {
                            try LocalStorage.save(self, queryIdentifier: queryIdentifier)
                        }
                    } else {
                        assertionFailure("Enable custom objectIds")
                    }
                }
            case .replace:
                if Parse.configuration.offlinePolicy.enabled {
                    if let error = error {
                        if error.hasNoInternetConnection {
                            try LocalStorage.save(self, queryIdentifier: queryIdentifier)
                            try LocalStorage.saveFetchObjects([self], method: method)
                        }
                    } else {
                        try LocalStorage.save(self, queryIdentifier: queryIdentifier)
                    }
                }
            case .update:
                if Parse.configuration.offlinePolicy.enabled {
                    if let error = error {
                        if error.hasNoInternetConnection {
                            try LocalStorage.save(self, queryIdentifier: queryIdentifier)
                            try LocalStorage.saveFetchObjects([self], method: method)
                        }
                    } else {
                        try LocalStorage.save(self, queryIdentifier: queryIdentifier)
                    }
                }
            }
        } else {
            if Parse.configuration.offlinePolicy.enabled {
                try LocalStorage.save(self, queryIdentifier: queryIdentifier)
            }
        }
    }
}

internal extension Sequence where Element: ParseObject {

    func saveLocally(method: Method? = nil,
                     queryIdentifier: String? = nil,
                     error: ParseError? = nil) throws {
        let objects = map { $0 }

        if let method = method {
            switch method {
            case .save:
                if Parse.configuration.offlinePolicy.enabled {
                    if let error = error {
                        if error.hasNoInternetConnection {
                            try LocalStorage.saveAll(objects, queryIdentifier: queryIdentifier)
                            try LocalStorage.saveFetchObjects(objects, method: method)
                        }
                    } else {
                        try LocalStorage.saveAll(objects, queryIdentifier: queryIdentifier)
                    }
                }
            case .create:
                if Parse.configuration.offlinePolicy.canCreate {
                    if Parse.configuration.isRequiringCustomObjectIds {
                        if let error = error {
                            if error.hasNoInternetConnection {
                                try LocalStorage.saveAll(objects, queryIdentifier: queryIdentifier)
                                try LocalStorage.saveFetchObjects(objects, method: method)
                            }
                        } else {
                            try LocalStorage.saveAll(objects, queryIdentifier: queryIdentifier)
                        }
                    } else {
                        assertionFailure("Enable custom objectIds")
                    }
                }
            case .replace:
                if Parse.configuration.offlinePolicy.enabled {
                    if let error = error {
                        if error.hasNoInternetConnection {
                            try LocalStorage.saveAll(objects, queryIdentifier: queryIdentifier)
                            try LocalStorage.saveFetchObjects(objects, method: method)
                        }
                    } else {
                        try LocalStorage.saveAll(objects, queryIdentifier: queryIdentifier)
                    }
                }
            case .update:
                if Parse.configuration.offlinePolicy.enabled {
                    if let error = error {
                        if error.hasNoInternetConnection {
                            try LocalStorage.saveAll(objects, queryIdentifier: queryIdentifier)
                            try LocalStorage.saveFetchObjects(objects, method: method)
                        }
                    } else {
                        try LocalStorage.saveAll(objects, queryIdentifier: queryIdentifier)
                    }
                }
            }
        } else {
            if Parse.configuration.offlinePolicy.enabled {
                try LocalStorage.saveAll(objects, queryIdentifier: queryIdentifier)
            }
        }
    }
}

fileprivate extension String {

    /**
     Creates a hidden file
     */
    var hiddenFile: Self {
        return "." + self
    }
}

fileprivate extension Sequence where Element == FetchObject {

    /**
     Returns a unique array of `FetchObject`'s where each element is the most recent version of itself.
     */
    var uniqueObjectsById: [Element] {
        let fetchObjects = map { $0 }.sorted(by: { $0.updatedAt > $1.updatedAt })

        var uniqueObjects: [Element] = []
        for fetchObject in fetchObjects {
            uniqueObjects.append(fetchObjects.first(where: { $0.objectId == fetchObject.objectId }) ?? fetchObject)
        }

        return uniqueObjects.isEmpty ? fetchObjects : uniqueObjects
    }

    func asParseObjects<T: ParseObject>(_ type: T.Type) throws -> [T] {
        let fileManager = FileManager.default

        let fetchObjectIds = map { $0 }.filter({ $0.className == T.className }).map({ $0.objectId })

        let objectsDirectoryPath = try ParseFileManager.objectsDirectory(className: T.className)
        let directoryObjectIds = try fileManager.contentsOfDirectory(atPath: objectsDirectoryPath.path)

        var objects: [T] = []

        for directoryObjectId in directoryObjectIds where fetchObjectIds.contains(directoryObjectId) {
            let contentPath = objectsDirectoryPath.appendingPathComponent(directoryObjectId,
                                                                          isDirectory: false)

            if fileManager.fileExists(atPath: contentPath.path) {
                let jsonData = try Data(contentsOf: contentPath)
                let object = try ParseCoding.jsonDecoder().decode(T.self, from: jsonData)

                objects.append(object)
            }
        }

        return objects
    }
}
