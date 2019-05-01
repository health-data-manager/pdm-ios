//
//  PDMHealthKit.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import Foundation
import HealthKit

// Provides a connection to HealthKit via the PDM.
// Note that HealthKit may not be available on all devices.
// It is noteably not available on the iPad.
class PDMHealthKit {
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

    let healthStore: HKHealthStore
    let availableTypes: Set<HKClinicalType>

    // Possibly creates the health kit connection. This depends on health data being available through HealthKit.
    init?() {
        guard HKHealthStore.isHealthDataAvailable() else {
            // If this device does not support health data, this will never work
            return nil
        }
        // If it is available, just create the health store.
        healthStore = HKHealthStore()
        var availableTypes = Set<HKClinicalType>()
        // Create types for all the various types we might access
        for type in PDMHealthKit.supportedTypes {
            guard let newType = HKObjectType.clinicalType(forIdentifier: type) else {
                // TODO: handle this in some way?
                print("Unable to create type \(type)")
                continue
            }
            availableTypes.insert(newType)
        }
        if availableTypes.isEmpty {
            // This should possibly be a fatal error.
            print("No requested types ever created.")
            return nil
        }
        self.availableTypes = availableTypes
    }

    // Sends a request to HealthKit for the various supported record types.
    func requestHealthRecordAccess(completion: @escaping (Bool, Error?) -> Void) {
        healthStore.requestAuthorization(toShare: nil, read: availableTypes, completion: completion)
    }
}
