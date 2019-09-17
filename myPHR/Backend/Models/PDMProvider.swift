//
//  PDMProvider.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import Foundation

/// A provider from within the PDM.
class PDMProvider {
    var id: Int64
    var parentId: Int64?
    var type: String
    var name: String
    var description: String
    var baseEndpoint: URL?
    var tokenEndpoint: URL?
    var authorizationEndpoint: URL?
    var scopes: String?
    var clientId: String?
    var clientSecret: String?
    var street: String?
    var city: String?
    var state: String?
    var zip: String?
    var logo: Data?

    init(id: Int64, type: String, name: String, description: String) {
        self.id = id
        self.type = type
        self.name = name
        self.description = description
    }

    init?(fromJSON json: [String: Any]) {
        // Grab required fields or fail
        guard let id = json["id"] as? NSNumber,
            let type = json["provider_type"] as? String,
            let name = json["name"] as? String,
            let description = json["description"] as? String else {
                return nil
        }
        self.id = id.int64Value
        self.type = type
        self.name = name
        self.description = description
        if let parentId = json["parent_id"] as? NSNumber {
            self.parentId = parentId.int64Value
        }
        if let baseEndpointString = json["base_endpoint"] as? String, let baseEndpoint = URL(string: baseEndpointString) {
            self.baseEndpoint = baseEndpoint
        }
        if let tokenEndpointString = json["token_endpoint"] as? String, let tokenEndpoint = URL(string: tokenEndpointString) {
            self.tokenEndpoint = tokenEndpoint
        }
        if let authorizationEndpointString = json["authorization_endpoint"] as? String, let authorizationEndpoint = URL(string: authorizationEndpointString) {
            self.authorizationEndpoint = authorizationEndpoint
        }
        // FIXME: Why do we receive these?
        self.clientId = json["client_id"] as? String
        self.clientSecret = json["client_secret"] as? String
        self.street = json["street"] as? String
        self.city = json["city"] as? String
        self.state = json["state"] as? String
        self.zip = json["zip"] as? String
        if let logo = json["logo"] as? String {
            self.logo = Data(base64Encoded: logo)
        }
    }

    static func providers(fromJSON json: [Any]) -> [PDMProvider]? {
        if json.isEmpty {
            return []
        }
        var result = [PDMProvider]()
        for o in json {
            guard let jsonObj = o as? [String: Any] else {
                continue
            }
            if let provider = PDMProvider(fromJSON: jsonObj) {
                result.append(provider)
            }
        }
        if result.isEmpty {
            return nil
        } else {
            return result
        }
    }
}

/// A link between a profile and a provider. These are mostly intended to be "short-lived."
struct PDMProviderProfileLink {
    var id: Int64
    var profileId: Int64
    var providerId: Int64
    var lastSync: Date?

    init(id: Int64, profileId: Int64, providerId: Int64, lastSync: Date?=nil) {
        self.id = id
        self.profileId = profileId
        self.providerId = providerId
        self.lastSync = lastSync
    }

    init(id: Int64, profileId: Int64, providerId: Int64, lastSyncISOString: String?) {
        let date: Date?
        if let lastSyncISOString = lastSyncISOString {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions.insert(.withFractionalSeconds)
            date = dateFormatter.date(from: lastSyncISOString)
        } else {
            date = nil
        }
        self.init(id: id, profileId: profileId, providerId: providerId, lastSync: date)
    }

    /// Potentially initializes this object with a JSON object. Returns `nil` if the object cannot be created because the JSON object is missing required fields or the fields are of the wrong type.
    init?(withJSON json: [String: Any]) {
        guard let id = json["id"] as? NSNumber,
            let profileId = json["profile_id"] as? NSNumber,
            let providerId = json["provider_id"] as? NSNumber else {
                return nil
        }
        self.init(id: id.int64Value, profileId: profileId.int64Value, providerId: providerId.int64Value, lastSyncISOString: json["last_sync"] as? String)
    }

    static func list(fromJSON json: [Any]) -> [PDMProviderProfileLink]? {
        // Return an empty list if there were none
        if json.count == 0 {
            return []
        }
        var result = [PDMProviderProfileLink]()
        for element in json {
            if let obj = element as? [String: Any], let link = PDMProviderProfileLink(withJSON: obj) {
                result.append(link)
            }
        }
        // Return nil if nothing could be parsed - assume that means a bad argument
        return result.isEmpty ? nil : result
    }
}
