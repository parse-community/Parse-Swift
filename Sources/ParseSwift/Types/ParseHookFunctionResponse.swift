//
//  ParseHookFunctionResponse.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/13/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation

public struct ParseHookFunctionResponse: Codable, Equatable {
    public let functionName: String
    public let url: URL?
    public let warning: String?
}
