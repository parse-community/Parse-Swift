//
//  Fileable.swift
//  ParseSwift
//
//  Created by Corey Baker on 12/27/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation

protocol Fileable: ParseType, Decodable, LocallyIdentifiable {
    var __type: String { get } // swiftlint:disable:this identifier_name
    var name: String { get set }
    var url: URL? { get set }
}

extension Fileable {
    var isSaved: Bool {
        return url != nil
    }

    mutating func hash(into hasher: inout Hasher) {
        if let url = url {
            hasher.combine(url)
        } else {
            hasher.combine(self.establishedLocalUUID)
        }
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        guard let lURL = lhs.url,
              let rURL = rhs.url else {
            guard let lhsUUID = lhs.localUUID,
                  let rhsUUID = rhs.localUUID else {
                //Can only compare objects that have a localUUID
                return false
            }
            return lhsUUID == rhsUUID
        }
        return lURL == rURL
    }
}
