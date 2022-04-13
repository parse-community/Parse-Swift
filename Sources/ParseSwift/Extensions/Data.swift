//
//  Data.swift
//  ParseSwift
//
//  Created by Corey Baker on 2/14/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

// Credit to: https://stackoverflow.com/questions/39075043/how-to-convert-data-to-hex-string-in-swift
internal extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let hexDigits = options.contains(.upperCase) ? "0123456789ABCDEF" : "0123456789abcdef"
        if #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *) {
            let utf8Digits = Array(hexDigits.utf8)
            return String(unsafeUninitializedCapacity: 2 * count) { (ptr) -> Int in
                var mutablePtr = ptr.baseAddress!
                for byte in self {
                    mutablePtr[0] = utf8Digits[Int(byte / 16)]
                    mutablePtr[1] = utf8Digits[Int(byte % 16)]
                    mutablePtr += 2
                }
                return 2 * count
            }
        } else {
            let utf16Digits = Array(hexDigits.utf16)
            var chars: [unichar] = []
            chars.reserveCapacity(2 * count)
            for byte in self {
                chars.append(utf16Digits[Int(byte / 16)])
                chars.append(utf16Digits[Int(byte % 16)])
            }
            return String(utf16CodeUnits: chars, count: chars.count)
        }
    }
}
