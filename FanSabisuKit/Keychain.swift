import Foundation
import Security

enum KeychainError: Error {
    case couldNotSave
    case wrongInput
    case couldNotRetrieve
}

enum KeychainKey: String {
    case oauthToken = "oauthToken"
    case oauthTokenSecret = "oauthTokenSecret"
    case userID = "userID"
    case screenName = "screenName"
}

public class Keychain {

    public init() {
        
    }

    public func store(oauth: OAuth) throws {
        guard let oauthToken = oauth.oauthToken?.data(using: .utf8) else {
            throw KeychainError.wrongInput
        }
        try store(value: oauthToken, for: KeychainKey.oauthToken.rawValue)

        guard let oauthTokenSecret = oauth.oauthTokenSecret?.data(using: .utf8) else {
            throw KeychainError.wrongInput
        }
        try store(value: oauthTokenSecret, for: KeychainKey.oauthTokenSecret.rawValue)

        guard let userID = oauth.userID?.data(using: .utf8) else {
            throw KeychainError.wrongInput
        }
        try store(value: userID, for: KeychainKey.userID.rawValue)

        guard let screenName = oauth.screenName?.data(using: .utf8) else {
            throw KeychainError.wrongInput
        }
        try store(value: screenName, for: KeychainKey.screenName.rawValue)
    }

    public func retrieve() throws -> OAuth {
        let oauthToken = try retrieve(for: KeychainKey.oauthToken.rawValue)
        let oauthTokenSecret = try retrieve(for: KeychainKey.oauthTokenSecret.rawValue)
        let userID = try retrieve(for: KeychainKey.userID.rawValue)
        let screenName = try retrieve(for: KeychainKey.screenName.rawValue)
        return OAuth(oauthToken: oauthToken, oauthTokenSecret: oauthTokenSecret, userID: userID, screenName: screenName)
    }

    func store(value: Data, for key: String) throws {
        let query = [kSecClass as String: kSecClassGenericPassword as String,
                     kSecAttrService as String: "FanSabisu",
                     kSecAttrAccount as String: key,
                     kSecValueData as String: value,
                     kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked as String] as [String : Any]
        SecItemDelete(query as CFDictionary)
        if errSecSuccess != SecItemAdd(query as CFDictionary, nil) {
            throw KeychainError.couldNotSave
        }
    }

    func retrieve(for key: String) throws -> String {
        let query = [kSecClass as String: kSecClassGenericPassword as String,
                     kSecAttrService as String: "FanSabisu",
                     kSecAttrAccount as String: key,
                     kSecReturnData as String: true,
                     kSecReturnAttributes as String: true,
                     kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked as String] as [String : Any]
        var result: AnyObject?
        if errSecSuccess != SecItemCopyMatching(query as CFDictionary, &result) {
            throw KeychainError.couldNotRetrieve
        }
        guard let dictionary = result as? [String: Any] else {
            throw KeychainError.couldNotRetrieve
        }
        guard let data = dictionary[kSecValueData as String] as? Data else {
            throw KeychainError.couldNotRetrieve
        }
        guard let value = String(data: data, encoding: .utf8) else {
            throw KeychainError.couldNotRetrieve
        }
        return value
    }

}
