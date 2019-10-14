//
//  HealthRecordJSONViewController.swift
//  myPHR
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import UIKit
import FHIR

/// This view controller exists to show the underlying JSON for a record. It's primarily intended for debugging purposes.
class HealthRecordJSONViewController: UIViewController {
    @IBOutlet weak var jsonTextView: UITextView!
    var record: FHIRResource?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let record = record else {
            jsonTextView.text = "No record (internal error)"
            return
        }
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: record.resource, options: [.prettyPrinted,.sortedKeys])
            jsonTextView.text = String(data: jsonData, encoding: .utf8)
        } catch {
            jsonTextView.text = "Could not convert record to JSON"
        }
    }
}
