//
//  ViewController.swift
//  Health Data Manager
//
//  Created by Potter, Dan on 3/1/19.
//  Copyright © 2019 MITRE. All rights reserved.
//

import UIKit
import HealthKit

// This is the first view shown after logging in. It's shown to give us a chance to warn the user if they haven't allowed us access to HealthKit yet.
class InitialViewController: UIViewController {
    @IBOutlet weak var loadingLabel: UILabel!
    @IBOutlet weak var retryButton: UIButton!

    var healthStore: HKHealthStore?
    var requestedTypes = Set<HKClinicalType>()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        checkHealthKitAccess()
    }

    func checkHealthKitAccess() {
        loadingLabel.text = "Checking if HealthKit is available..."
        retryButton.isHidden = true
        if HKHealthStore.isHealthDataAvailable() {
            // Only create the health store when we know it's potentially available
            if healthStore == nil {
                healthStore = HKHealthStore()
            }

            // Create types for all the various types we might access
            for type in PatientDataManager.supportedTypes {
                guard let newType = HKObjectType.clinicalType(forIdentifier: type) else {
                    // TODO: handle this in some way?
                    print("Unable to create type \(type)")
                    continue
                }
                requestedTypes.insert(newType)
            }

            if requestedTypes.isEmpty {
                failInternalError("Unable to instantiate any health care record types")
            }

            // Clinical types are read-only.
            // Go ahead and force the unwrap because it can't be nil here anyway (as it was created above)
            healthStore!.requestAuthorization(toShare: nil, read: requestedTypes) { (success, error) in
                guard success else {
                    DispatchQueue.main.async {
                        self.failInternalError(error!.localizedDescription)
                    }
                    return
                }
                // Otherwise, on success, we're ready to go
                DispatchQueue.main.async {
                    self.loadHealthRecords()
                }
            }
        }
    }

    @IBAction func retryCheckAccess(_ sender: Any) {
        checkHealthKitAccess()
    }

    func loadHealthRecords() {
        loadingLabel.text = "Loading Health Data Manager..."
        // Segue to the actual UI
        performSegue(withIdentifier: "Main", sender: self)
    }

    func failInternalError(_ message: String) {
        loadingLabel.text = "Unable to initialize HealthKit: \(message)"
        retryButton.isHidden = false
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        switch (segue.identifier ?? "") {

        case "Main":
            // FIXME: Do this in some better fashion (if there is one)
            guard let navigationView = segue.destination as? UINavigationController else {
                fatalError("Segueing to unknown destination \(segue.destination)")
            }
            guard let healthRecordTableView = navigationView.visibleViewController as? HealthRecordTableViewController else {
                fatalError("Segueing to unknown destination \(segue.destination)")
            }
            healthRecordTableView.healthStore = healthStore
            healthRecordTableView.availableRecordTypes = requestedTypes
        default:
            fatalError("Unexpected segue: \(String(describing: segue.identifier))")
        }
    }
}

