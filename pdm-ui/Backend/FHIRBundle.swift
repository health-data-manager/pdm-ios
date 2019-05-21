//
//  FHIRBundle.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import Foundation

/// Base class of FHIR resources.
class FHIRResource {
    /// The type of this resource. Conceptually this could be an enum but for now it's a string.
    var resourceType: String

    init(_ resourceType: String) {
        self.resourceType = resourceType
    }

    /// Checks to see if this object matches the query. The default implementation only checks to see if the type matches.
    func matches(_ query: [String: Any]) -> Bool {
        return query.count == 1 && query["resourceType"] as? String == resourceType
    }

    /// Handles getting a value for resourceType. Otherwise returns nil.
    func getValue(forField field: String) -> Any? {
        if field == "resourceType" {
            return resourceType
        } else {
            return nil
        }
    }

    /// Gets a string based on a field name.
    func getString(forField field: String) -> String? {
        return getValue(forField: field) as? String
    }

    static func create(fromJSON json: Any) -> FHIRResource? {
        // For now just always create the generic objects.
        // Eventually this might special-case some types.
        return GenericFHIRResource(fromJSON: json)
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

/// A generic FHIR resource. Rather than try and implement a true FHIR library, this implements just enough to allow access to the contents of FHIR objects.
class GenericFHIRResource: FHIRResource {
    var resource: [String: Any]
    init?(fromJSON json: Any) {
        guard let resource = getResourceFromJSON(json),
            let resourceType = resource["resourceType"] as? String else {
                return nil
        }
        self.resource = resource
        super.init(resourceType)
    }

    /// Override to check if the fields match
    override func matches(_ query: [String: Any]) -> Bool {
        return matchDicts(document: resource, query: query)
    }

    override func getValue(forField field: String) -> Any? {
        return lookupValue(forField: field, inDict: resource)
    }
}

/// A FHIR Bundle. Eventually this should likely be replaced with an actual FHIR library but at present this exists as a place-holder.
class FHIRBundle: FHIRResource {
    var entries = [FHIRResource]()

    init?(fromJSON json: Any) {
        guard let jsonObj = json as? [String: Any], let resourceType = jsonObj["resourceType"] as? String, resourceType == "Bundle" else {
            return nil
        }
        // For now, just jam the entire thing into an entry
        guard let entries = jsonObj["entry"] as? [Any] else {
            return nil
        }
        // Go through the entries and create whatever resources we can
        for entry in entries {
            if let resource = FHIRResource.create(fromJSON: entry) {
                self.entries.append(resource)
            }
        }
        super.init("Bundle")
    }

    /**
     Very basic search that looks for any resource that matches the given object - that is, has fields that match the given JSON object. There's no special logic here, and everything has to be an exact match.

     This is **not** designed to be well optimized! It operates at O(n) speed. If there are a ton of resources, a better searching mechanism should be used. This will likely not be changed any time in the future.

     - Parameter query: an object containing fields that must match (exactly) to return a document
     - Returns: a list of all matching resources
     */
    func search(_ query: [String: Any]) -> [FHIRResource] {
        var result = [FHIRResource]()
        for resource in entries {
            if resource.matches(query) {
                result.append(resource)
            }
        }
        return result
    }
}
