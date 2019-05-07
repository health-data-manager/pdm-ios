//
//  HealthRecordViewController.swift
//  Health Data Manager
//
//  Created by Potter, Dan on 3/13/19.
//  Copyright © 2019 MITRE. All rights reserved.
//

import UIKit
import HealthKit

class HealthRecordViewController: UIViewController {
    var healthRecord: HKClinicalRecord!

    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var urlText: UITextField!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var shareButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = healthRecord.displayName
        typeLabel.text = typeToString(healthRecord.clinicalType)
        if let fhirResource = healthRecord.fhirResource {
            if let sourceURL = fhirResource.sourceURL {
                urlText.text = sourceURL.absoluteString
            } else {
                urlText.text = "(none)"
            }
            textView.text = String(data: fhirResource.data, encoding: .utf8)
        } else {
            urlText.text = "(no data)"
            textView.text = "(no data)"
        }
        navigationItem.rightBarButtonItem = shareButton
    }

    func typeToString(_ type: HKClinicalType) -> String {
        switch(type.identifier) {
        case HKClinicalTypeIdentifier.allergyRecord.rawValue:
            return "Allergy"
        case HKClinicalTypeIdentifier.conditionRecord.rawValue:
            return "Condition"
        case HKClinicalTypeIdentifier.immunizationRecord.rawValue:
            return "Immunization"
        case HKClinicalTypeIdentifier.labResultRecord.rawValue:
            return "Lab Result"
        case HKClinicalTypeIdentifier.medicationRecord.rawValue:
            return "Medication"
        case HKClinicalTypeIdentifier.procedureRecord.rawValue:
            return "Procedure"
        case HKClinicalTypeIdentifier.vitalSignRecord.rawValue:
            return "Vital Sign"
        default:
            return type.description
        }
    }

    @IBAction func shareRecord(_ sender: Any) {
        uploadToPatientDataManager()
    }

    func uploadToPatientDataManager() {
        if let app = UIApplication.shared.delegate as? AppDelegate {
            if let pdm = app.patientDataManager {
                pdm.uploadHealthRecords([healthRecord], completionCallback: { (error: Error?) -> Void in
                    DispatchQueue.main.async {
                        if (error != nil) {
                            print("An error occurred.")
                        } else {
                            self.uploadCompleted()
                        }
                    }
                })
            }
        }
    }

    func uploadCompleted() {
        // Create the action buttons for the alert.
        let defaultAction = UIAlertAction(title: "OK", style: .default) { (action) in
            // Do nothing
        }

        // Create and configure the alert controller.
        let alert = UIAlertController(title: "Upload Successful", message: "The upload completed successfully.", preferredStyle: .alert)
        alert.addAction(defaultAction)

        self.present(alert, animated: true) {
            // The alert was presented
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
