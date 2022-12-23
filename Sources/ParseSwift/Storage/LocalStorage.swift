//
//  LocalStorage.swift
//  
//
//  Created by Damian Van de Kauter on 03/12/2022.
//

import Foundation

internal struct LocalStorage {
    static let fileManager = FileManager.default
    
    static func save<T: ParseObject>(_ object: T,
                                     queryIdentifier: String?) throws {
        let objectData = try ParseCoding.jsonEncoder().encode(object)
        
        guard let objectId = object.objectId else {
            throw ParseError(code: .unknownError, message: "Object has no valid objectId")
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
                throw ParseError(code: .unknownError, message: "Object has no valid objectId")
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
    
    static func saveFetchObjects<T: ParseObject>(_ objects: [T],
                                                 method: Method) throws {
        let objectsDirectoryPath = try ParseFileManager.objectsDirectory()
        let fetchObjectsPath = objectsDirectoryPath.appendingPathComponent(ParseConstants.fetchObjectsFile.hiddenFile)
        
        var fetchObjects = try getFetchObjects()
        fetchObjects.append(contentsOf: try objects.map({ try FetchObject($0, method: method) }))
        
        let jsonData = try ParseCoding.jsonEncoder().encode(fetchObjects)
        
        if fileManager.fileExists(atPath: fetchObjectsPath.path) {
            try jsonData.write(to: fetchObjectsPath)
        } else {
            fileManager.createFile(atPath: fetchObjectsPath.path, contents: jsonData, attributes: nil)
        }
    }
    
    static func getFetchObjects() throws -> [FetchObject] {
        let objectsDirectoryPath = try ParseFileManager.objectsDirectory()
        let fetchObjectsPath = objectsDirectoryPath.appendingPathComponent(ParseConstants.fetchObjectsFile.hiddenFile)
        
        if fileManager.fileExists(atPath: fetchObjectsPath.path) {
            let jsonData = try Data(contentsOf: fetchObjectsPath)
            return try ParseCoding.jsonDecoder().decode([FetchObject].self, from: jsonData).uniqueObjectsById
        } else {
            return []
        }
    }
    
    static func saveQueryObjects<T: ParseObject>(_ objects: [T],
                                                 queryIdentifier: String) throws {
        let objectsDirectoryPath = try ParseFileManager.objectsDirectory()
        let queryObjectsPath = objectsDirectoryPath.appendingPathComponent(ParseConstants.queryObjectsFile.hiddenFile)
        
        var queryObjects = try getQueryObjects()
        queryObjects[queryIdentifier] = try objects.map({ try QueryObject($0) })
        
        let jsonData = try ParseCoding.jsonEncoder().encode(queryObjects)
        
        if fileManager.fileExists(atPath: queryObjectsPath.path) {
            try jsonData.write(to: queryObjectsPath)
        } else {
            fileManager.createFile(atPath: queryObjectsPath.path, contents: jsonData, attributes: nil)
        }
    }
    
    static func getQueryObjects() throws -> [String : [QueryObject]] {
        let objectsDirectoryPath = try ParseFileManager.objectsDirectory()
        let queryObjectsPath = objectsDirectoryPath.appendingPathComponent(ParseConstants.queryObjectsFile.hiddenFile)
        
        if fileManager.fileExists(atPath: queryObjectsPath.path) {
            let jsonData = try Data(contentsOf: queryObjectsPath)
            return try ParseCoding.jsonDecoder().decode([String : [QueryObject]].self, from: jsonData)
        } else {
            return [:]
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

internal struct FetchObject: Codable {
    let objectId: String
    let className: String
    let updatedAt: Date
    let method: Method
    
    init<T : ParseObject>(_ object : T, method: Method) throws {
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
    
    init<T : ParseObject>(_ object : T) throws {
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
                     error: ParseError? = nil) throws {
        if let method = method {
            switch method {
            case .save:
                if Parse.configuration.offlinePolicy.enabled {
                    try LocalStorage.save(self, queryIdentifier: queryIdentifier)
                    
                    if let error = error, error.hasNoInternetConnection {
                        try LocalStorage.saveFetchObjects([self], method: method)
                    }
                }
            case .create:
                if Parse.configuration.offlinePolicy.canCreate {
                    if Parse.configuration.isRequiringCustomObjectIds {
                        try LocalStorage.save(self, queryIdentifier: queryIdentifier)
                        
                        if let error = error, error.hasNoInternetConnection {
                            try LocalStorage.saveFetchObjects([self], method: method)
                        }
                    } else {
                        throw ParseError(code: .unknownError, message: "Enable custom objectIds")
                    }
                }
            case .replace:
                if Parse.configuration.offlinePolicy.enabled {
                    try LocalStorage.save(self, queryIdentifier: queryIdentifier)
                    
                    if let error = error, error.hasNoInternetConnection {
                        try LocalStorage.saveFetchObjects([self], method: method)
                    }
                }
            case .update:
                if Parse.configuration.offlinePolicy.enabled {
                    try LocalStorage.save(self, queryIdentifier: queryIdentifier)
                    
                    if let error = error, error.hasNoInternetConnection {
                        try LocalStorage.saveFetchObjects([self], method: method)
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
                    try LocalStorage.saveAll(objects, queryIdentifier: queryIdentifier)
                    
                    if let error = error, error.hasNoInternetConnection {
                        try LocalStorage.saveFetchObjects(objects, method: method)
                    }
                }
            case .create:
                if Parse.configuration.offlinePolicy.canCreate {
                    if Parse.configuration.isRequiringCustomObjectIds {
                        try LocalStorage.saveAll(objects, queryIdentifier: queryIdentifier)
                        
                        if let error = error, error.hasNoInternetConnection {
                            try LocalStorage.saveFetchObjects(objects, method: method)
                        }
                    } else {
                        throw ParseError(code: .unknownError, message: "Enable custom objectIds")
                    }
                }
            case .replace:
                if Parse.configuration.offlinePolicy.enabled {
                    try LocalStorage.saveAll(objects, queryIdentifier: queryIdentifier)
                    
                    if let error = error, error.hasNoInternetConnection {
                        try LocalStorage.saveFetchObjects(objects, method: method)
                    }
                }
            case .update:
                if Parse.configuration.offlinePolicy.enabled {
                    try LocalStorage.saveAll(objects, queryIdentifier: queryIdentifier)
                    
                    if let error = error, error.hasNoInternetConnection {
                        try LocalStorage.saveFetchObjects(objects, method: method)
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

fileprivate extension Sequence where Element == FetchObject {
    
    var uniqueObjectsById: [Element] {
        let objects = map { $0 }.sorted(by: { $0.updatedAt > $1.updatedAt })
        
        var uniqueObjects: [Element] = []
        for object in objects {
            uniqueObjects.append(objects.first(where: { $0.objectId == object.objectId }) ?? object)
        }
        
        return uniqueObjects.isEmpty ? objects : uniqueObjects
    }
}
