//
//  ParseStorage.swift
//  
//
//  Created by Pranjal Satija on 7/19/20.
//

// MARK: ParseStorage
public struct ParseStorage {
    public static var shared = ParseStorage()

    var primitiveStore: PrimitiveObjectStore = CodableInMemoryPrimitiveObjectStore()
    var secureStore: PrimitiveObjectStore = KeychainStore.shared

    enum Keys {
        static let currentUser = "_currentUser"
        static let currentInstallation = "_currentInstallation"
        static let defaultACL = "_defaultACL"
    }
}
