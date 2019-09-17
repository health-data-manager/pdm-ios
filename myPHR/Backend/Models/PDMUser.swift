//
//  PDMUser.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import Foundation

/// Represents a user in the Patient Data Manager
struct PDMUser {
    let id: Int
    let firstName: String
    let lastName: String
    let email: String
    let createdAt: Date
    let updatedAt: Date

    /**
     Initialize with all required data elements.

     - Parameters:
         - id: the ID
         - firstName: the user's given name
         - lastName: the user's family name
         - email: the email address associated with this account
         - createdAt: when the account was created
         - updatedAt: the last time the account information was updated
     */
    init(withId id: Int, firstName: String, lastName: String, email: String, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /**
     Initializes from JSON. If the JSON object could not be used (it was missing required data or the required data was not of the required types) this initalizer will fail.

     - Parameter json: a JSON object
     */
    init?(fromJSON json: [String: Any]) {
        guard let id = json["id"] as? Int else {
            print("Could not convert ID \(json["id"] ?? "nil") to Int")
            return nil
        }
        guard let firstName = json["first_name"] as? String,
            let lastName = json["last_name"] as? String,
            let email = json["email"] as? String,
            let createdAtString = json["created_at"] as? String,
            let updatedAtString = json["updated_at"] as? String else {
                return nil
        }
        let dateParser = ISO8601DateFormatter()
        dateParser.formatOptions.insert(.withFractionalSeconds)
        guard let createdAt = dateParser.date(from: createdAtString),
            let updatedAt = dateParser.date(from: updatedAtString) else {
                return nil
        }
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /**
     Initialize from data containing JSON in UTF8 format. This initializer can fail if the actual JSON data can not be parsed.

     - Throws: if the JSON could not be parsed
     - Parameter data: the data to load
     */
    init?(fromData data: Data) throws {
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        guard let jsonDict = json as? [String: Any] else {
            return nil
        }
        self.init(fromJSON: jsonDict)
    }

    /// Checks a password to ensure it meets complexity requirements.
    /// Password should be 8-70 characters and include at least one of the following character classes: uppercase, lowercase, digit and "special" characters
    /// The regexp is taken from the current backend config. It's somewhat unclear how well it functions within Swift's somewhat weird definition of a "character." (Specifically, if a user uses things like emojis, will that potentially make this allow a password through to the backend that it will reject?)
    static func checkComplexityOfPassword(_ password: String) -> Bool {
        return password.range(of: "(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&*-]).{8,70}", options: .regularExpression, range: nil, locale: nil) != nil
    }
}
