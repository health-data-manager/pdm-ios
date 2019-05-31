//
//  PDMHealthKit.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import Foundation
import HealthKit

enum PDMHealthKitError: Error {
    case multipleQueryErrors([Error])
}

/// Provides a connection to HealthKit via the PDM.
/// Note that HealthKit may not be available on all devices. It is noteably not available on the iPad.
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

    /// The health store being used by the app
    let healthStore: HKHealthStore
    /// The available clinical record types
    let availableTypes: Set<HKClinicalType>

    /// The query dispatch queue. Note that it is intentionally serial: it is mostly used for adding data to collections.
    private let queryDispatchQueue = DispatchQueue(label: "org.mitre.PDM.queryQueue", attributes: [])

    /// Possibly creates the health kit connection. This depends on health data being available through HealthKit.
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

    /// Sends a request to HealthKit for the various supported record types. This may pop up a HealthKit UI requesting the user allow access.
    ///
    /// - Parameters:
    ///   - completion: a completion handler invoked when the request completes
    ///   - success: `true` if the request was successful, `false` otherwise
    ///   - error: non-`nil` if an error prevented the request
    func requestHealthRecordAccess(completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        healthStore.requestAuthorization(toShare: nil, read: availableTypes, completion: completion)
    }

    /// Request all available health records on the device.
    ///
    /// - Parameters:
    ///   - completionCallback: a callback invoked when the records are available
    ///   - records: the records loaded or `nil` if loading failed
    ///   - error: non-`nil` if an error prevented record loading
    func queryAllHealthRecords(completionCallback: @escaping (_ records: [HKClinicalRecord]?, _ error: Error?) -> Void) {
        // Because we have to run multiple queries, we need a dispatch group to known when they're all done
        let group = DispatchGroup()
        // The records we want to return
        var records = [HKClinicalRecord]()
        // Any errors
        var errors = [Error]()
        for recordType in availableTypes {
            let query = HKSampleQuery(sampleType: recordType, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
                defer {
                    // No matter what happens, we leave the group
                    group.leave()
                }
                if let error = error {
                    // Add the error to the list of errors
                    self.queryDispatchQueue.async(flags: .barrier) {
                        errors.append(error)
                    }
                    return
                }
                guard let samples = samples, let resultingRecords = samples as? [HKClinicalRecord] else {
                    // If there were no samples just skip?
                    return
                }
                self.queryDispatchQueue.async(flags: .barrier) {
                    records.append(contentsOf: resultingRecords)
                }
            }
            // Enter the group
            group.enter()
            healthStore.execute(query)
        }
        group.notify(queue: DispatchQueue.main) {
            switch errors.count {
            case 0:
                completionCallback(records, nil)
            case 1:
                completionCallback(nil, errors[0])
            default:
                completionCallback(nil, PDMHealthKitError.multipleQueryErrors(errors))
            }
        }
    }
}
