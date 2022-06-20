//
//  ParseHookTriggerable.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/14/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

/**
 The types of triggers available.
 */
public enum ParseHookTriggerType: String, Codable {
    case beforeLogin, afterLogin, afterLogout,
         beforeSave, afterSave, beforeDelete, afterDelete,
         beforeFind, afterFind,
         beforeConnect, beforeSubscribe, afterEvent
}

public protocol ParseHookTriggerable: ParseHookable {
    var className: String? { get set }
    var triggerName: ParseHookTriggerType? { get set }
    var url: URL? { get set }
}

// MARK: Default Implementation
public extension ParseHookTriggerable {
    init(className: String, triggerName: ParseHookTriggerType, url: URL) {
        self.init()
        self.className = className
        self.triggerName = triggerName
        self.url = url
    }
}
