//
//  String+Extension.swift
//  MoyaNetwork
//
//  Created by lester on 2024/2/26.
//

import Foundation
import CommonCrypto

enum CryptoType {
    case MD5, SHA1, SHA224, SHA256, SHA384, SHA512

    var HMACAlgorithm: CCHmacAlgorithm {
        var result: Int = 0
        switch self {
        case .MD5: result = kCCHmacAlgMD5
        case .SHA1: result = kCCHmacAlgSHA1
        case .SHA224: result = kCCHmacAlgSHA224
        case .SHA256: result = kCCHmacAlgSHA256
        case .SHA384: result = kCCHmacAlgSHA384
        case .SHA512: result = kCCHmacAlgSHA512
        }
        return CCHmacAlgorithm(result)
    }

    var digestLength: Int {
        var result: Int32 = 0
        switch self {
        case .MD5: result = CC_MD5_DIGEST_LENGTH
        case .SHA1: result = CC_SHA1_DIGEST_LENGTH
        case .SHA224: result = CC_SHA224_DIGEST_LENGTH
        case .SHA256: result = CC_SHA256_DIGEST_LENGTH
        case .SHA384: result = CC_SHA384_DIGEST_LENGTH
        case .SHA512: result = CC_SHA512_DIGEST_LENGTH
        }
        return Int(result)
    }
}

extension String {
    
    var hmacText: String {
        return hmac(algorithm: .SHA256, key: "&YS1@#./")
    }

    var md5: String {
        hmac(algorithm: .MD5, key: "@#$&ZXCV")
    }

    // HMAC 加密
    private func hmac(algorithm: CryptoType, key: String) -> String {
        let str = cString(using: String.Encoding.utf8)
        let strLen = Int(lengthOfBytes(using: String.Encoding.utf8))
        let digestLen = algorithm.digestLength
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
        let keyStr = key.cString(using: String.Encoding.utf8)
        let keyLen = Int(key.lengthOfBytes(using: String.Encoding.utf8))

        CCHmac(algorithm.HMACAlgorithm, keyStr!, keyLen, str!, strLen, result)

        let hash = NSMutableString()
        for i in 0 ..< digestLen {
            hash.appendFormat("%02x", result[i])
        }
        let digest = String(hash).lowercased()
        result.deallocate()
        return digest
    }
}
