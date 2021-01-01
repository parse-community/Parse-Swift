//
//  LocallyIdentifiable.swift
//  ParseSwift
//
//  Created by Corey Baker on 12/31/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation

public protocol LocallyIdentifiable: Encodable, Hashable {
    var localUUID: UUID? { get set }
}

extension LocallyIdentifiable {

    public var establishedLocalUUID: UUID {
        mutating get {
            if self.localUUID == nil {
                self.localUUID = UUID()
            }
            return self.localUUID!
        }
    }

    mutating func hash(into hasher: inout Hasher) {
        hasher.combine(self.establishedLocalUUID)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        guard let lhsUUID = lhs.localUUID,
              let rhsUUID = rhs.localUUID else {
            //Can only compare objects that have a localUUID
            return false
        }
        return lhsUUID == rhsUUID
    }
}
