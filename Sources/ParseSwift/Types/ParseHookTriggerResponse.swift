//
//  ParseHookTriggerResponse.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/14/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

public struct ParseHookTriggerResponse: Codable, Equatable {
    public let className: String
    public let triggerName: ParseHookTriggerType
    public let url: URL?
    public let warning: String?
}
