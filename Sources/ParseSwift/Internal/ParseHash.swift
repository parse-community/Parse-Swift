//
//  ParseHash.swift
//  ParseSwift
//
//  Created by Corey Baker on 12/22/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//
#if !os(Linux) && !os(Android)
import Foundation
import CommonCrypto

struct ParseHash {
    static func md5HashFromData(_ data: Data) -> String {
        var dataBytes = [UInt8](repeating: 0, count: data.count)
        data.copyBytes(to: &dataBytes, count: data.count)

        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        var md5 = CC_MD5_CTX()
        CC_MD5_Init(&md5)
        CC_MD5_Update(&md5, dataBytes, CC_LONG(data.count))
        CC_MD5_Final(&digest, &md5)

        return String(format: "%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                      digest[0], digest[1], digest[2], digest[3],
                      digest[4], digest[5], digest[6], digest[7],
                      digest[8], digest[9], digest[10], digest[11],
                      digest[12], digest[13], digest[14], digest[15])
    }

    static func md5HashFromString(_ string: String) -> String? {
        guard let data = string.data(using: .utf8) else {
            return nil
        }
        return md5HashFromData(data)
    }
}
#endif
