//
//  ParseHookTriggerable.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/14/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

/**
 The types of triggers 
 */
public enum ParseHookTriggerType: String, Codable {
    case beforeLogin, afterLogin, afterLogout,
         beforeSave, afterSave, beforeDelete, afterDelete,
         beforeFind, afterFind,
         beforeConnect, beforeSubscribe, afterEvent
}
