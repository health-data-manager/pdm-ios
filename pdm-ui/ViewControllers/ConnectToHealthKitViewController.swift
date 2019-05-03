//
//  ViewController.swift
//  Health Data Manager
//
//  Created by Potter, Dan on 3/1/19.
//  Copyright © 2019 MITRE. All rights reserved.
//

import UIKit

// This is the first view shown after logging in. It's shown to give us a chance to warn the user if they haven't allowed us access to HealthKit yet.
class ConnectToHealthKitViewController: UIViewController {
    @IBOutlet weak var loadingLabel: UILabel!
    @IBOutlet weak var retryButton: PDMButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkHealthKitAccess()
    }

    func checkHealthKitAccess() {
        loadingLabel.text = "Checking if HealthKit is available..."
        retryButton.isHidden = true
        // Do any additional setup after loading the view, typically from a nib.
        guard let pdm = patientDataManager, let healthKit = pdm.healthKit else {
            // If neither are available, we can't do anything, and need to just skip ahead
            segueToHome()
            return
        }

        healthKit.requestHealthRecordAccess() { (success, error) in
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

    @IBAction func retryCheckAccess(_ sender: Any) {
        checkHealthKitAccess()
    }

    func loadHealthRecords() {
        loadingLabel.text = "Loading Patient Data Manager..."
        // Segue to the actual UI
        segueToHome()
    }

    func failInternalError(_ message: String) {
        loadingLabel.text = "Unable to initialize HealthKit: \(message)"
        retryButton.isHidden = false
    }

    func segueToHome() {
        performSegue(withIdentifier: "Home", sender: self)
    }

//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        super.prepare(for: segue, sender: sender)
//    }
}

