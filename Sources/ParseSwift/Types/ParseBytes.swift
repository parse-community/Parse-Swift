//
//  ParseBytes.swift
//  ParseSwift
//
//  Created by Corey Baker on 7/9/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

/**
  `ParseBytes` is used to store base 64 data.
*/
public struct ParseBytes: ParseTypeable, Hashable {
    private let __type: String = "Bytes" // swiftlint:disable:this identifier_name
    public let base64: String

    enum CodingKeys: String, CodingKey {
        case __type // swiftlint:disable:this identifier_name
        case base64
    }

    /**
      Create new `ParseBytes` instance with the specified base64 string.
       - parameter base64: A base64 string.
     */
    public init(base64: String) {
        self.base64 = base64
    }

    /**
      Create new `ParseBytes` instance with the specified data.
       - parameter data: The data to encode to a base64 string.
     */
    public init(data: Data) {
        self.base64 = data.base64EncodedString()
    }
}

extension ParseBytes {
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        base64 = try values.decode(String.self, forKey: .base64)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(__type, forKey: .__type)
        try container.encode(base64, forKey: .base64)
    }
}
