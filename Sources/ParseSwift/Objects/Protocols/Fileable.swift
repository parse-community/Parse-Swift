//
//  Fileable.swift
//  ParseSwift
//
//  Created by Corey Baker on 12/27/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation

protocol Fileable: Encodable {
    var __type: String { get } // swiftlint:disable:this identifier_name
    var name: String { get set }
    var url: URL? { get set }
    var localUUID: UUID { mutating get }
}

extension Fileable {
    var isSaved: Bool {
        return url != nil
    }

    // Equatable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        guard let lURL = lhs.url,
              let rURL = rhs.url else {
            var lhs = lhs
            var rhs = rhs
            return lhs.localUUID == rhs.localUUID
        }
        return lURL == rURL
    }

    //Hashable
    public func hash(into hasher: inout Hasher) {
        var fileable = self
        hasher.combine(fileable.localUUID)
    }
}
