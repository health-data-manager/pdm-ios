//
//  FHIRBundle.swift
//  FHIR
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import Foundation
import os.log

/// A FHIR Bundle. Eventually this should likely be replaced with an actual FHIR library but at present this exists as a place-holder.
public class FHIRBundle: FHIRResource {
    /// The entities in this bundle
    public var entries = [FHIRResource]()

    public init?(fromJSON json: Any) {
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
            } else {
                os_log("Unable to parse resource for entity in bundle")
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
    public func search(_ query: [String: Any]) -> [FHIRResource] {
        var result = [FHIRResource]()
        for resource in entries {
            if resource.matches(query) {
                result.append(resource)
            }
        }
        return result
    }
}
