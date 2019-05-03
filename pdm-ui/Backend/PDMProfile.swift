//
//  PDMProfile.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import Foundation

/**
 A profile within the PDM.
 */
class PDMProfile {
    let profileId: Int64
    let userId: Int64
    let patientId: UUID
    var name: String
    var firstName: String?
    var lastName: String?
    var gender: String?
    var dateOfBirth: Date?
    var middleName: String?
    var street: String?
    var city: String?
    var state: String?
    var zip: String?
    var relationship: String?
    var telephone: String?
    var telephoneUse: String?

    /**
     Initializes with just the required parameters

     - Parameters:
        - userId: the user ID
        - patientId: the patient ID
        - name: the patient's name
     */
    init(id profileId: Int64, userId: Int64, patientId: UUID, name: String) {
        self.profileId = profileId
        self.userId = userId
        self.patientId = patientId
        self.name = name
    }

    /**
     Initializes using a JSON document.

     - Parameter json: a JSON object (as parsed by JSONSerialization)
     */
    init?(withJSON json: [String: Any]) {
        guard let profileId = json["id"] as? NSNumber, let userId = json["user_id"] as? NSNumber else {
            return nil
        }
        guard let patientIdString = json["patient_id"] as? String, let patientId = UUID(uuidString: patientIdString) else {
            return nil
        }
        guard let name = json["name"] as? String else {
            return nil
        }
        self.profileId = profileId.int64Value
        self.userId = userId.int64Value
        self.patientId = patientId
        self.name = name
        // The rest are all optional anyway
        self.firstName = json["first_name"] as? String
        self.lastName = json["last_name"] as? String
        self.gender = json["gender"] as? String
        let dateFormatter = ISO8601DateFormatter()
        if let dobString = json["dob"] as? String {
            self.dateOfBirth = dateFormatter.date(from: dobString)
        }
        self.middleName = json["middle_name"] as? String
        self.street = json["street"] as? String
        self.zip = json["zip"] as? String
        self.relationship = json["relationship"] as? String
        self.telephone = json["telephone"] as? String
        self.telephoneUse = json["telephone_use"] as? String
    }

    static func profilesFromJSON(json: [Any]) -> [PDMProfile] {
        // Always return *something*
        var result = [PDMProfile]()
        for jsonObj in json {
            if let jsonDict = jsonObj as? [String: Any] {
                if let profile = PDMProfile(withJSON: jsonDict) {
                    result.append(profile)
                }
            }
        }
        return result
    }

    static func profilesFromJSON(data: Data) throws -> [PDMProfile]? {
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        guard let jsonArray = json as? [Any] else {
            return nil
        }
        return profilesFromJSON(json: jsonArray)
    }
}
