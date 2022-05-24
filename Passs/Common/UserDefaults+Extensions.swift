//
//  UserDefaults+Extensions.swift
//  Passs
//
//  Created by Dmitry Fedorov on 24.02.2022.
//

import Foundation

@propertyWrapper struct UserDefaultsBacked<Value> {
    let key: String
    var storage: UserDefaults = .standard

    var wrappedValue: Value? {
        get { storage.value(forKey: key) as? Value }
        set { storage.setValue(newValue, forKey: key) }
    }
}
