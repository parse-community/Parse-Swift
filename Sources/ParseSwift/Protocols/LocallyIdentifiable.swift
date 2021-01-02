//
//  LocallyIdentifiable.swift
//  ParseSwift
//
//  Created by Corey Baker on 12/31/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation

public protocol LocallyIdentifiable: Encodable, Hashable {
    var localId: UUID { get set }
}

extension LocallyIdentifiable {

    mutating func hash(into hasher: inout Hasher) {
        hasher.combine(self.localId)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.localId == rhs.localId
    }
}
