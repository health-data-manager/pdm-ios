//
//  HealthRecordViewController.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import UIKit

/// This is currently mostly a placeholder view controller
class HealthRecordViewController: UIViewController {
    @IBOutlet weak var jsonTextView: UITextView!
    var record: FHIRResource?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let record = record else {
            jsonTextView.text = "No record (internal error)"
            return
        }
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: record.asJSON(), options: [.prettyPrinted,.sortedKeys])
            jsonTextView.text = String(data: jsonData, encoding: .utf8)
        } catch {
            jsonTextView.text = "Could not convert record to JSON"
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
