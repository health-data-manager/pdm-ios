//
//  FHIRBundle.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import Foundation

/// A FHIR Bundle. Eventually this should likely be replaced with an actual FHIR library but at present this exists as a place-holder.
class FHIRBundle {
    var entry: [Any]?

    init?(fromJSON json: Any) {
        guard let jsonObj = json as? [String: Any], let resourceType = jsonObj["resourceType"] as? String, resourceType == "Bundle" else {
            return nil
        }
        // For now, just jam the entire thing into an entry
        guard let entries = jsonObj["entry"] as? [Any] else {
            return nil
        }
        self.entry = entries
    }
}
