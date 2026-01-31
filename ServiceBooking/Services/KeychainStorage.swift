//
//  KeychainStorage.swift
//  ServiceBooking
//
//  Безопасное хранение device_id, api_key, client_id (по спецификации веб-консоли)
//

import Foundation
import Security

/// Хранилище чувствительных данных в Keychain
enum KeychainStorage {
    private static let serviceName = "com.servicebooking.app"
    
    private static func makeQuery(account: String, forSave: Bool = false) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account
        ]
        if forSave {
            query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        }
        return query
    }
    
    static func save(_ value: String, forAccount account: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        
        var query = makeQuery(account: account, forSave: true)
        query[kSecValueData as String] = data
        
        SecItemDelete(makeQuery(account: account) as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    static func load(forAccount account: String) -> String? {
        var query = makeQuery(account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    static func delete(forAccount account: String) -> Bool {
        SecItemDelete(makeQuery(account: account) as CFDictionary) == errSecSuccess
    }
    
    // MARK: - App Keys
    
    static let deviceIdAccount = "device_id"
    static let apiKeyAccount = "api_key"
    static let clientIdAccount = "client_id"
    
    static var deviceId: String {
        if let stored = load(forAccount: deviceIdAccount) {
            return stored
        }
        let newId = UUID().uuidString
        _ = save(newId, forAccount: deviceIdAccount)
        return newId
    }
    
    static var apiKey: String? {
        get { load(forAccount: apiKeyAccount) }
        set {
            if let value = newValue {
                _ = save(value, forAccount: apiKeyAccount)
            } else {
                _ = delete(forAccount: apiKeyAccount)
            }
        }
    }
    
    static var clientId: String? {
        get { load(forAccount: clientIdAccount) }
        set {
            if let value = newValue {
                _ = save(value, forAccount: clientIdAccount)
            } else {
                _ = delete(forAccount: clientIdAccount)
            }
        }
    }
    
    static func clearCredentials() {
        apiKey = nil
        clientId = nil
    }
}
