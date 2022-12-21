//
//  LocalStorage.swift
//  
//
//  Created by Damian Van de Kauter on 03/12/2022.
//

import Foundation

internal struct LocalStorage {
    
    static func save<T: ParseObject>(_ object: T,
                                     queryIdentifier: String?) throws {
        let fileManager = FileManager.default
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
    
    static func save<T: ParseObject>(_ objects: [T],
                                     queryIdentifier: String?) throws {
        let fileManager = FileManager.default
        
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
                                  queryIdentifier: String) throws -> [U]? {
        print("[LocalStorage] get objects")
        print("[LocalStorage] queryIdentifier: \(String(describing: queryIdentifier))")
        guard let queryObjects = try getQueryObjects()[queryIdentifier] else { return nil }
        
        var allObjects: [U] = []
        for queryObject in queryObjects {
            print("[LocalStorage] get id: \(queryObject.objectId)")
            let objectsDirectoryPath = try ParseFileManager.objectsDirectory(className: queryObject.className)
            let objectPath = objectsDirectoryPath.appendingPathComponent(queryObject.objectId)
            
            let objectData = try Data(contentsOf: objectPath)
            if let object = try? ParseCoding.jsonDecoder().decode(U.self, from: objectData) {
                allObjects.append(object)
            }
        }
        
        return (allObjects.isEmpty ? nil : allObjects)
    }
    
    static func saveQueryObjects<T: ParseObject>(_ objects: [T],
                                                 queryIdentifier: String) throws {
        let fileManager = FileManager.default
        
        let objectsDirectoryPath = try ParseFileManager.objectsDirectory()
        let queryObjectsPath = objectsDirectoryPath.appendingPathComponent(ParseConstants.queryObjectsFile)
        
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
        let fileManager = FileManager.default
        
        let objectsDirectoryPath = try ParseFileManager.objectsDirectory()
        let queryObjectsPath = objectsDirectoryPath.appendingPathComponent(ParseConstants.queryObjectsFile)
        
        if fileManager.fileExists(atPath: queryObjectsPath.path) {
            let jsonData = try Data(contentsOf: queryObjectsPath)
            return try ParseCoding.jsonDecoder().decode([String : [QueryObject]].self, from: jsonData)
        } else {
            return [:]
        }
    }
}

internal struct QueryObject: Codable {
    let objectId: String
    let className: String
    let queryDate: Date
    
    init<T : ParseObject>(_ object : T) throws {
        guard let objectId = object.objectId else {
            throw ParseError(code: .unknownError, message: "Object has no valid objectId")
        }
        self.objectId = objectId
        self.className = object.className
        self.queryDate = Date()
    }
}

internal extension ParseObject {
    
    func saveLocally(method: Method,
                     queryIdentifier: String? = nil) throws {
        switch method {
        case .save:
            if Parse.configuration.offlinePolicy.enabled {
                try LocalStorage.save(self, queryIdentifier: queryIdentifier)
            }
        case .create:
            if Parse.configuration.offlinePolicy.canCreate {
                if Parse.configuration.isRequiringCustomObjectIds {
                    try LocalStorage.save(self, queryIdentifier: queryIdentifier)
                } else {
                    throw ParseError(code: .unknownError, message: "Enable custom objectIds")
                }
            }
        case .replace:
            if Parse.configuration.offlinePolicy.enabled {
                try LocalStorage.save(self, queryIdentifier: queryIdentifier)
            }
        case .update:
            if Parse.configuration.offlinePolicy.enabled {
                try LocalStorage.save(self, queryIdentifier: queryIdentifier)
            }
        }
    }
}

internal extension Sequence where Element: ParseObject {
    
    func saveLocally(method: Method,
                     queryIdentifier: String? = nil) throws {
        let objects = map { $0 }
        
        switch method {
        case .save:
            if Parse.configuration.offlinePolicy.enabled {
                try LocalStorage.save(objects, queryIdentifier: queryIdentifier)
            }
        case .create:
            if Parse.configuration.offlinePolicy.canCreate {
                try LocalStorage.save(objects, queryIdentifier: queryIdentifier)
            }
        case .replace:
            if Parse.configuration.offlinePolicy.enabled {
                try LocalStorage.save(objects, queryIdentifier: queryIdentifier)
            }
        case .update:
            if Parse.configuration.offlinePolicy.enabled {
                try LocalStorage.save(objects, queryIdentifier: queryIdentifier)
            }
        }
    }
}
