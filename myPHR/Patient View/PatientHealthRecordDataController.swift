//
//  PatientHealthRecordDataController.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import Foundation
import FHIR

/// Various categories that could contain PHR data. These represent the categories that appear within the health record UI.
enum PHRCategory: String, CaseIterable {
    case allergies
    case diseases
    case genomics
    case immunizations
    case labsVitals
    case medications
    case patient
    case treatment

    var localizedName: String {
        switch self {
        case .allergies:
            return "Allergies"
        case .diseases:
            return "Diseases"
        case .genomics:
            return "Genomics"
        case .immunizations:
            return "Immunizations"
        case .labsVitals:
            return "Labs / Vitals"
        case .medications:
            return "Medications"
        case .patient:
            return "Patient"
        case .treatment:
            return "Treatment"
        }
    }

    /// Gets the category from the path component of a URL. (Every other part of the URL is ignored: this is equivalent to calling categoryFromPath() with the path itself.)
    ///
    /// If there is no matching category, this returns nil.
    static func categoryFromURLPath(_ url: URL) -> PHRCategory? {
        return categoryFromPath(url.path)
    }

    /// Gets the category from the path component of a URL. Currently this simply removes any leading slash and looks up the name of the category based on the name of the enum. A future version might look at only the first component of the path.
    ///
    /// - Parameter path: the path to look up
    /// - Returns: the catgory for that path, if there is one
    static func categoryFromPath(_ path: String) -> PHRCategory? {
        var lookupPath = path
        if (path.starts(with: "/")) {
            lookupPath = String(path[path.index(after: path.startIndex)...])
        }
        return PHRCategory(rawValue: lookupPath)
    }
}

/// Manages computing and finding the data to show based on a user's health records. Currently this requires a record bundle.
///
/// It also seems likely that a future version of this will become asynchronous, as it seems likely data lookups will be moved to happen when a request for data is first made. This may in the future cache responses.
class PatientHealthRecordDataController {
    /// Current method of setting the records to use. This may change in the future.
    var records: FHIRBundle?

    init() { }

    /// Boxes that only exist for demo purposes. THIS WILL BE REMOVED WHEN ALL DATA COMES FROM THE PDM
    static var demoBoxes = [
        PatientHealthTile(title: "Condition", measurement: "Sinusitis", type: .condition),
        PatientHealthTile(title: "Cholesterol HDL", measurement: "53.5", type: .lab, units: "mg/dL"),
        PatientHealthTile(title: "Triglycerides", measurement: "86", type: .lab, units: "mg/dL"),
        PatientHealthTile(title: "BMI-body mass index", measurement: "26", type: .vital, units: "kg/m\u{B2}")
    ]

    /// Determine the set of tiles to display to the user based on the given record bundle.
    ///
    /// - Parameter records: the health records to use to make the decisions
    /// - Returns: a set of tiles containing data to display to the user
    func calculatePatientData() -> [PatientHealthTile] {
        var result = [PatientHealthTile]()
        if let records = records {
            // See if we can find a cancer resource
            let cancerResources = records.search([
                "meta": [
                    "profile": [
                        "http://hl7.org/fhir/us/shr/StructureDefinition/onco-core-PrimaryCancerCondition"
                    ]
                ]
            ])
            // For now, just use the first one
            if let cancerResource = cancerResources.first, let cancerType = cancerResource.getString(forField: "code.text") {
                let tile = PatientHealthTile(title: "Cancer", measurement: cancerType, type: .disease)
                if let cancerStageCoding = cancerResource.getValue(forField: "stage.summary.coding") as? [Any],
                    let cancerStageElement = cancerStageCoding.first,
                    let cancerStageCodingObj = cancerStageElement as? [String: Any],
                    let cancerStage = cancerStageCodingObj["display"] as? String {
                    tile.title = cancerStage
                }
                result.append(tile)
                // Add some more static boxes
                result.append(PatientHealthTile(title: "Next Appointment with Dr. Rusk99", measurement: "21.May", type: .appointment, delta: "10:00AM"))
                result.append(PatientHealthTile(title: "Patient Data Receipt from Dr. Rusk99", measurement: "Routine Visit", type: .healthReceipt, link: "pdm://health-receipt/1"))
            }
        }
        // Add in demo boxes as necessary
        result.append(contentsOf: PatientHealthRecordDataController.demoBoxes[0...(3-result.count)])
        return result
    }

    /// Calculates the care plan. This is pretty likely to change in the future.
    func calculateCarePlan() -> CarePlan {
        // See if there is a cancer resource
        let cancerResources = records?.search([
            "meta": [
                "profile": [
                    "http://hl7.org/fhir/us/shr/StructureDefinition/onco-core-PrimaryCancerCondition"
                ]
            ]
        ]) ?? []
        if cancerResources.isEmpty {
            // Return a default
            return CarePlan(title: "Go for a 15 minute jog or bike ride", description: "Regular exercise decreases your risk of developing certain diseases, including type 2 diabetes or high blood pressure.")
        } else {
            // Return a cancer-specific one
            return CarePlan(title: "Prepare for treatment discussion", description: "Here are some examples of the types of questions you may want to ask Dr. Rusk99 on 21.May, 10AM.", name: "Colon Cancer Care Plan", link: "pdm://careplan/colonCancer")
        }
    }

    /// Finds matching records for a given category.
    func findRecordsForCategory(_ category: PHRCategory) -> [FHIRResource] {
        // If there are no records, then return an empty list
        guard let records = records else { return [] }
        // TODO (maybe): Sort these in some fashion here?
        switch category {
        case .allergies:
            return records.search(["resourceType" : "AllergyIntolerance"])
        case .diseases:
            return records.search(["resourceType" : "Condition"])
        case .labsVitals:
            return records.search(["resourceType" : "Observation"])
        case .immunizations:
            return records.search(["resourceType" : "Immunization"])
        case .medications:
            return records.search(["resourceType" : "MedicationOrder"])
        default:
            // For any unsupported category, return an empty list
            return []
        }
    }
}
