//
//  PDMUploadResults.swift
//  myPHR
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import Foundation
import HealthKit

/// This simply contains information on waht was sent to the PDM.
class PDMUploadResults {
    let categories: [String: UInt]

    /// Initializes the results with the given set of clinical records.
    init(_ records: [HKClinicalRecord]) {
        // Essentially all we do is count the number of records of each type, and that's it
        var mutableCategories = [String: UInt]()
        for record in records {
            let type = record.clinicalType.identifier
            let currentCount = mutableCategories[type]
            if let count = currentCount {
                mutableCategories[type] = count + 1
            } else {
                mutableCategories[type] = 1
            }
        }
        categories = mutableCategories
    }
}
