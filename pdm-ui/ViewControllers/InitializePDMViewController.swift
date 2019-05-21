//
//  InitializePDMViewController.swift
//  Health Data Manager
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import UIKit
import HealthKit

/// Handles loading the various parts of the PDM.
class InitializePDMViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var loadingLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var retryButton: PDMButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        retryButton.isHidden = true
        // Prepare the views while we're loaded
        guard let pdm = patientDataManager else {
            // If the PDM is not available, there is nothing to do. Stop immediately.
            pdmNotAvailable()
            return
        }
        guard pdm.healthKit != nil else {
            showLoadingProfile()
            return
        }
        showInitializingHealthKit()
    }

    override func viewDidAppear(_ animated: Bool) {
        // Once the view has appeared, check if we have HealthKit
        checkHealthKitAccess()
    }

    func checkHealthKitAccess() {
        guard let pdm = patientDataManager else {
            // If the PDM is not available, there is nothing to do. Stop immediately.
            pdmNotAvailable()
            return
        }

        guard let healthKit = pdm.healthKit else {
            // If we have no HealthKit, skip ahead to loading data from the PDM
            loadProfile()
            return
        }

        showInitializingHealthKit()
        healthKit.requestHealthRecordAccess() { (success, error) in
            guard success else {
                DispatchQueue.main.async {
                    self.failInternalError(error!.localizedDescription)
                }
                return
            }
            // Otherwise, on success, we're ready to go
            DispatchQueue.main.async {
                self.loadProfile()
            }
        }
    }

    @IBAction func retry(_ sender: Any) {
        //checkHealthKitAccess()
    }

    func loadProfile() {
        guard let pdm = patientDataManager else {
            pdmNotAvailable()
            return
        }
        showLoadingProfile()
        pdm.getActiveProfile() { profile, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.handleError(error, title: "Could not load profile")
                    return
                }
                // Now that we have the profile, we can send whatever we have from HealthKit (assuming HealthKit is available)
                self.doFhirClientLogin()
            }
        }
    }

    func doFhirClientLogin() {
        guard let pdm = patientDataManager else {
            pdmNotAvailable()
            return
        }
        guard pdm.healthKit != nil else {
            // Skip this step
            loadHealthRecords()
            return
        }
        showSendingHealthKit("Logging in to PDM...")
        pdm.fhirClientLogin() { error in
            DispatchQueue.main.async {
                if let error = error {
                    // This means we couldn't log in as a FHIR client. This should be handled in some fashion but for now, skip ahead
                    print("Could not log in as a FHIR client: \(error)")
                    self.loadHealthRecords()
                } else {
                    self.sendHealthKitRecords()
                }
            }
        }
    }

    func sendHealthKitRecords() {
        guard let pdm = patientDataManager else {
            pdmNotAvailable()
            return
        }
        guard pdm.healthKit != nil else {
            // If HealthKit isn't available, skip ahead to loading the records back from the PDM
            loadHealthRecords()
            return
        }
        showSendingHealthKit("Loading local health records...")
        pdm.uploadHealthRecordsFromHealthKit() { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.handleError(error, title: "Could not load health records")
                    return
                } else {
                    self.loadHealthRecords()
                }
            }
        }
    }

    func loadHealthRecords() {
        guard let pdm = patientDataManager else {
            pdmNotAvailable()
            return
        }
        showLoadingProfile("Fetching health records...")
        pdm.loadHealthRecords() { json, error in
            DispatchQueue.main.async {
                self.segueToHome()
            }
        }
    }

    func failInternalError(_ message: String) {
        loadingLabel.text = "Unable to initialize HealthKit: \(message)"
        retryButton.isHidden = false
    }

    func segueToHome() {
        performSegue(withIdentifier: "Home", sender: self)
    }

    func pdmNotAvailable() {
        showLoadingMessage(title: "PDM Not Available", description: "The Patient Data Manager was not configured correctly.")
    }

    func showInitializingHealthKit() {
        showLoadingMessage(title: "Checking for HealthKit", description: "Requesting accessing to your health records via HealthKit...", loading: "Checking if HealthKit is available...")
    }

    func showSendingHealthKit(_ loading: String="Sending health records...") {
        showLoadingMessage(title: "Sending HealthKit", description: "Sending data from HealthKit to the PDM.", loading: loading)
    }

    func showLoadingProfile(_ loading: String="Fetching profile...") {
        showLoadingMessage(title: "Loading Patient Information...", description: "Getting your patient information from the Patient Data Manager...", loading: loading)
    }

    func showLoadingMessage(title: String, description: String, loading: String?=nil) {
        titleLabel.text = title
        descriptionLabel.text = description
        loadingLabel.isHidden = loading == nil
        if let loadingText = loading {
            loadingLabel.text = loadingText
        }
        activityIndicator.isHidden = loading == nil
        retryButton.isHidden = true
    }

    func handleError(_ error: Error, title: String) {
        presentErrorAlert(error, title: title)
        titleLabel.text = "Could Not Start PDM"
        descriptionLabel.text = error.localizedDescription
        activityIndicator.isHidden = true
        loadingLabel.isHidden = true
        // TODO: Enable the retry button
    }

//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        super.prepare(for: segue, sender: sender)
//    }
}

