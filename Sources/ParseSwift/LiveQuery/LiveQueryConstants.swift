//
//  LiveQueryConstants.swift
//  ParseSwift
//
//  Created by Corey Baker on 11/3/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

/**
 Represents an update on a specific object from the `ParseLiveQuery` Server.
 - Entered: The object has been updated, and is now included in the query.
 - Left:    The object has been updated, and is no longer included in the query.
 - Created: The object has been created, and is a part of the query.
 - Updated: The object has been updated, and is still a part of the query.
 - Deleted: The object has been deleted, and is no longer included in the query.
 */
public enum Event<T: ParseObject>: Equatable {
    /// The object has been updated, and is now included in the query.
    case entered(T)

    /// The object has been updated, and is no longer included in the query.
    case left(T)

    /// The object has been created, and is a part of the query.
    case created(T)

    /// The object has been updated, and is still a part of the query.
    case updated(T)

    /// The object has been deleted, and is no longer included in the query.
    case deleted(T)

    init?(event: EventResponse<T>) {
        switch event.op {
        case .enter: self = .entered(event.object)
        case .leave: self = .left(event.object)
        case .create: self = .created(event.object)
        case .update: self = .updated(event.object)
        case .delete: self = .deleted(event.object)
        default: return nil
        }
    }

    public static func == <T>(lhs: Event<T>, rhs: Event<T>) -> Bool {
        switch (lhs, rhs) {
        case (.entered(let obj1), .entered(let obj2)): return obj1 == obj2
        case (.left(let obj1), .left(let obj2)):       return obj1 == obj2
        case (.created(let obj1), .created(let obj2)): return obj1 == obj2
        case (.updated(let obj1), .updated(let obj2)): return obj1 == obj2
        case (.deleted(let obj1), .deleted(let obj2)): return obj1 == obj2
        default: return false
        }
    }
}
