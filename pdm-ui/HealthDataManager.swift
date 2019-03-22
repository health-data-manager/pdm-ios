//
//  HealthDataManager.swift
//  Health Data Manager
//
//  Created by Potter, Dan on 3/13/19.
//  Copyright © 2019 MITRE. All rights reserved.
//

import Foundation
import HealthKit

// The "actual" HealthDataManager. This is intended to be a singleton that represents the connection to the HealthDataManager app.
class HealthDataManager {
    // It's probably possible to create this list via reflection but conceptually we should limit it to documents we can handle anyway
    static let supportedTypes = [
        HKClinicalTypeIdentifier.allergyRecord,
        HKClinicalTypeIdentifier.conditionRecord,
        HKClinicalTypeIdentifier.immunizationRecord,
        HKClinicalTypeIdentifier.labResultRecord,
        HKClinicalTypeIdentifier.medicationRecord,
        HKClinicalTypeIdentifier.procedureRecord,
        HKClinicalTypeIdentifier.vitalSignRecord
    ]
}
