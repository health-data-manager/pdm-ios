//
//  Resource.swift
//  FHIR
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import Foundation

/// Base class for FHIR resources.
///
/// The generic FHIR resource maintains the original JSON record, to maintain extended fields.
public class FHIRResource {
    /// The type of this resource. Conceptually this could be an enum but for now it's a string. This is currently optional, although if it's left blank, it generates an invalid object.
    public var resourceType: String?
    /// The original JSON data. Note that modifying this will NOT change the underlying view and, at present, changing the model will NOT change the JSON data.
    public var resource: [String: Any]

    public init(_ resourceType: String) {
        self.resourceType = resourceType
        self.resource = [String: Any]()
    }

    /// Generate the basic resource from the JSON object. Note that this will always succeed and may generate a somewhat useless object.
    public init(fromJSON json: [String: Any]) {
        self.resourceType = json["resourceType"] as? String
        self.resource = json
    }

    /// Checks to see if this object matches the query object.
    public func matches(_ query: [String: Any]) -> Bool {
        return matchDicts(document: resource, query: query)
    }

    /// Handles getting a value for resourceType. Otherwise returns nil.
    public func getValue(forField field: String) -> Any? {
        return lookupValue(forField: field, inDict: resource)
    }

    /// Gets a string based on a field name.
    public func getString(forField field: String) -> String? {
        return getValue(forField: field) as? String
    }

    /// Attempt to locate a string to describe this resource.
    public func describe() -> String {
        // TODO: As the various resource types are implemented, this code will be moved there
        var result: String?
        var suffix: String?
        if resourceType == "Condition" {
            result = codingToString("code")
        } else if resourceType == "Observation" {
            result = codingToString("code")
            suffix = valueToString("valueQuantity")
        } else if resourceType == "MedicationOrder" {
            result = codingToString("medicationCodeableConcept")
        } else if resourceType == "Immunization" {
            result = codingToString("vaccineCode")
        } else if resourceType == "AllergyIntolerance" {
            result = codingToString("substance")
        }
        var finalResult = result ?? resourceType ?? "Unknown"
        if let suffix = suffix {
            finalResult.append(", ")
            finalResult.append(suffix)
        }
        return finalResult
    }

    public static func create(fromJSON json: Any) -> FHIRResource? {
        // For now just always create the generic objects.
        // Eventually this might special-case some types.
        guard let resourceJson = getResourceFromJSON(json) else { return nil }
        if let resourceType = resourceJson["resourceType"] as? String {
            if resourceType == AllergyIntolerance.resourceType {
                return AllergyIntolerance(fromJSON: resourceJson)
            }
        }
        return FHIRResource(fromJSON: resourceJson)
    }

    private func codingToString(_ conceptName: String) -> String? {
        guard let concept = getValue(forField: conceptName) as? [String: Any] else {
            // If the concept doesn't exist, we can't use it at all
            return nil
        }
        // Concept may contain a text value we should use
        if let text = concept["text"] as? String {
            return text
        }
        // Otherwise, try the coding field
        guard let coding = concept["coding"] as? [Any],
            let firstCoding = coding.first as? [String: Any] else {
                return nil
        }
        return firstCoding["display"] as? String
    }

    private func valueToString(_ valueName: String) -> String? {
        guard let valueQuantity = getValue(forField: valueName) as? [String: Any],
            let value = valueQuantity["value"] else { return nil }
        var result: String
        if let valueNumber = value as? NSNumber {
            result = valueNumber.stringValue
        } else if let valueString = value as? String {
            result = valueString
        } else {
            return nil
        }
        if let unit = valueQuantity["unit"] as? String {
            if let fhirUnit = FHIRUnit(unit) {
                result.append(fhirUnit.humanReadable())
            } else {
                result.append(unit)
            }
        }
        return result
    }
}

func getResourceFromJSON(_ json: Any) -> [String: Any]? {
    guard let jsonObj = json as? [String: Any] else { return nil }
    // If the object contains a single entry called "resource" that's what we want
    if let resource = jsonObj["resource"] {
        if let result = resource as? [String: Any] {
            // Make sure this has a type in it
            if result["resourceType"] is String {
                return result
            }
            // Otherwise fall through and try the object itself
        }
    }
    // Otherwise, if this has a resourceType that's a string, use that
    if jsonObj["resourceType"] is String {
        return jsonObj
    }
    return nil
}

func matchFields(documentField: Any, queryField: Any) -> Bool {
    if let docStr = documentField as? String, let queryStr = queryField as? String {
        return docStr == queryStr
    } else if let docDict = documentField as? [String: Any], let queryDict = queryField as? [String: Any] {
        return matchDicts(document: docDict, query: queryDict)
    } else if let docArray = documentField as? [Any], let queryArray = queryField as? [Any] {
        return matchArrays(document: docArray, query: queryArray)
    } else {
        // If we're here, assume they didn't match
        return false
    }
}

func matchDicts(document: [String: Any], query: [String: Any]) -> Bool {
    for (field, queryFieldValue) in query {
        guard let docFieldValue = document[field], matchFields(documentField: docFieldValue, queryField: queryFieldValue) else {
            // If we don't have the same field or the fields don't match, return false
            return false
        }
    }
    // If we made it through, we match
    return true
}

func matchArrays(document: [Any], query: [Any]) -> Bool {
    queryFieldLoop: for queryFieldValue in query {
        // The question is if *any* field in the query matches this
        for docFieldValue in document {
            if matchFields(documentField: docFieldValue, queryField: queryFieldValue) {
                continue queryFieldLoop
            }
        }
        // If we never continued, we never found a match, so this is false
        return false
    }
    // If we made it through, we match
    return true
}

func lookupValue(forField field: String, inDict dict: [String: Any]) -> Any? {
    if let dotIdx = field.firstIndex(of: ".") {
        // In this case, we will be recursing.
        let localField = String(field[..<dotIdx])
        guard let value = dict[localField] else { return nil }
        // If there's a remaining value, it MUST be a dict
        guard let remaining = value as? [String: Any] else { return nil }
        let remainingField = String(field[field.index(after: dotIdx)...])
        return lookupValue(forField: remainingField, inDict: remaining)
    } else {
        // Otherwise return whatever we got
        return dict[field]
    }
}
