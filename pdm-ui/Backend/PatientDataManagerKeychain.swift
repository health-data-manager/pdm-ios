//
//  PatientDataManagerKeychain.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import Foundation
import Security

enum KeychainError: Error {
    /// There is no persisted password
    case noPassword
    /// The password data in the keychain does not match the expected format
    case unexpectedPasswordData
    /// An unhandled OS error occurred
    case unhandledError(status: OSStatus)

    public var errorDescription: String? {
        switch self {
        case .noPassword:
            return NSLocalizedString("No account credentials are stored.", comment: "No password")
        case .unexpectedPasswordData:
            return NSLocalizedString("The keychain record is invalid (the expected data was not present within it).", comment: "Unexpected password data")
        case .unhandledError(let status):
            return String(format: NSLocalizedString("An unhandled OS error occurred. (Error %d)", comment: "Unhandled error"), status)
        }
    }
}

struct PDMCredentials {
    var username: String
    var password: String
    init(username: String, password: String) {
        self.username = username
        self.password = password
    }
}

extension PatientDataManager {
    func getCredentialsFromKeychain() throws -> PDMCredentials {
        guard let host = rootURL.host else {
            throw PatientDataManagerError.invalidConfiguration
        }
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrServer as String: host,
                                    kSecMatchLimit as String: kSecMatchLimitOne,
                                    kSecReturnAttributes as String: true,
                                    kSecReturnData as String: true]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status != errSecItemNotFound else { throw KeychainError.noPassword }
        guard status == errSecSuccess else { throw KeychainError.unhandledError(status: status) }
        guard let existingItem = item as? [String : Any],
            let passwordData = existingItem[kSecValueData as String] as? Data,
            let password = String(data: passwordData, encoding: String.Encoding.utf8),
            let account = existingItem[kSecAttrAccount as String] as? String
            else {
                throw KeychainError.unexpectedPasswordData
        }
        return PDMCredentials(username: account, password: password)
    }

    func storeCredentialsInKeychain(_ credentials: PDMCredentials) throws {
        guard let host = rootURL.host else {
            throw PatientDataManagerError.invalidConfiguration
        }
        let account = credentials.username
        let password = credentials.password.data(using: String.Encoding.utf8)!
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrAccount as String: account,
                                    kSecAttrServer as String: host,
                                    kSecValueData as String: password]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.unhandledError(status: status) }
    }

    @discardableResult func signInAsUserFromKeychain(completionHandler: @escaping (_ error: Error?) -> Void) throws -> URLSessionTask? {
        let credentials = try getCredentialsFromKeychain()
        return signInAsUser(email: credentials.username, password: credentials.password, completionHandler: completionHandler)
    }
}
