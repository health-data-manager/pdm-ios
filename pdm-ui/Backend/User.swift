//
//  User.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import Foundation

// Represents a user in the Patient Data Manager
struct User {
    let id: Int
    let firstName: String
    let lastName: String
    let email: String
    let createdAt: Date
    let updatedAt: Date

    init(withId id: Int, firstName: String, lastName: String, email: String, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init?(fromJSON json: [String: Any]) {
        guard let id = json["id"] as? Int else {
            print("Could not convert ID \(json["id"] ?? "nil") to Int")
            return nil
        }
        guard let firstName = json["first_name"] as? String else {
            return nil
        }
        guard let lastName = json["last_name"] as? String else {
            return nil
        }
        guard let email = json["email"] as? String else {
            return nil
        }
        guard let createdAtString = json["created_at"] as? String else {
            return nil
        }
        guard let updatedAtString = json["updated_at"] as? String else {
            return nil
        }
        let dateParser = ISO8601DateFormatter()
        dateParser.formatOptions.insert(.withFractionalSeconds)
        guard let createdAt = dateParser.date(from: createdAtString) else {
            return nil
        }
        guard let updatedAt = dateParser.date(from: updatedAtString) else {
            return nil
        }
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init?(fromData data: Data) throws {
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        guard let jsonDict = json as? [String: Any] else {
            return nil
        }
        self.init(fromJSON: jsonDict)
    }
}
