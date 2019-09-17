//
//  MessageBundle.swift
//  pdm-ui
//
//  Created by Potter, Dan on 3/22/19.
//  Copyright © 2019 MITRE. All rights reserved.
//

import Foundation
import HealthKit

// Eventually this should probably use a proper FHIR library, but for now:

enum MessageBundleError: Error {
    case missingFhirData
}

class MessageBundle {
    var entries = [[String: Any?]]()

    func addRecordAsEntry(_ record: HKClinicalRecord) throws {
        if let fhir = record.fhirResource {
            let json = try JSONSerialization.jsonObject(with: fhir.data, options: [])
            if let jsonDict = json as? [String: Any] {
                addEntry(jsonDict, fullUrl: fhir.sourceURL?.absoluteString ?? "")
            }
        } else {
            throw MessageBundleError.missingFhirData
        }
    }

    /// Adds as many records as possible, potentially raising an error if the record JSON cannot be converted.
    func addRecordsAsEntry(_ records: [HKClinicalRecord]) throws {
        for record in records {
            try addRecordAsEntry(record)
        }
    }

    func addEntry(_ entry: [String: Any?], fullUrl: String) {
        entries.append([
            "fullUrl": fullUrl,
            "resource": entry
        ])
    }

    func addEntry(_ entry: [String: Any?]) {
        entries.append(entry)
    }

    func createMessageHeader() {
        // This appears to be unused by the HDM but is conceptually required
        entries.append([ "resourceType": "MessageHeader" ])
    }

    func addPatientId(_ patientId: String) {
        addEntry([
            "resourceType": "Parameters",
            "parameter": [
                [
                    "name": "health_data_manager_profile_id",
                    "valueString": patientId
                ]
            ]
        ], fullUrl: "")
    }

    func createJSON() -> [String: Any] {
        return [
            "resourceType": "Bundle",
            "type": "message",
            "entry": entries
        ]
    }

    func createJSONAsData() throws -> Data {
        return try JSONSerialization.data(withJSONObject: createJSON(), options: [])
    }
}
