//
//  Utils.swift
//  Liv3
//
//  Created by Razvan Rujoiu on 14/05/2020.
//  Copyright © 2020 Stas Seldin. All rights reserved.
//

import Foundation

public class RUtility {
    
    public static func isValidPhone(phone: String) -> Bool {
        let phoneRegex = "^[0-9+]{0,1}+[0-9]{5,16}$"
        let phoneTest = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phoneTest.evaluate(with: phone)
    }
    
    
    
}
