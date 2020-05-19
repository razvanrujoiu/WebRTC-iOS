//
//  CryptoUtil.swift
//  Liv3
//
//  Created by Razvan Rujoiu on 19/05/2020.
//  Copyright © 2020 Stas Seldin. All rights reserved.
//

import Foundation
import CryptoSwift

public class CryptoUtil {
    
    public static func hashSHA2(inputByteArray: [UInt8]) -> [UInt8] {
        let hash = inputByteArray.sha256()
        return hash
    }
    
    public static func encryptAES128(inputContent: [UInt8], key: String) -> [UInt8] {
        let keyHash = hashSHA2(inputByteArray: Array(key.utf8))
        let aesKey = Array(keyHash.prefix(16))
        let iv = Array(keyHash.prefix(16))
        var aesEncrypted = Array<UInt8>()
        do {
            aesEncrypted = try AES(key: aesKey, blockMode: CBC(iv: iv), padding: .pkcs7).encrypt(inputContent)
        } catch {
            print("❤️ Error while encrypting AES")
        }
        return aesEncrypted
    }
    
    public static func decryptAES128(inputContent: [UInt8], key: String) -> [UInt8] {
        let keyHash = hashSHA2(inputByteArray: Array(key.utf8))
        let aesKey = Array(keyHash.prefix(16))
        let iv = Array(keyHash.prefix(16))
        var aesDecrypted = Array<UInt8>()
        do {
            aesDecrypted = try AES(key: aesKey, blockMode: CBC(iv: iv), padding: .pkcs7).decrypt(inputContent)
        } catch {
            print("❤️ Error while decrypting AES")
        }
        return aesDecrypted
        
    }
    
//    public static func getAesDecryptionKey() -> [UInt8] {
//       // TODO
//    }
}
