//
//  LocallyIdentifiable.swift
//  ParseSwift
//
//  Created by Corey Baker on 12/31/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation

public protocol LocallyIdentifiable: Encodable, Hashable {
    var __localUUID: UUID? { get set } // swiftlint:disable:this identifier_name
}

public extension LocallyIdentifiable {
    var localUUID: UUID {
        mutating get {
            if self.__localUUID == nil {
                self.__localUUID = UUID()
            }
            return __localUUID!
        }
    }

    // Equatable
    static func == (lhs: Self, rhs: Self) -> Bool {
        var lhs = lhs
        var rhs = rhs
        return lhs.localUUID == rhs.localUUID
    }
}
