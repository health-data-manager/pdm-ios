//
//  PatientHealthRecordViewController.swift
//  pdm-ui
//
//  Created by Potter, Dan on 5/2/19.
//  Copyright © 2019 MITRE. All rights reserved.
//

import UIKit

class PatientHealthRecordViewController: UIViewController {

    @IBOutlet weak var healthRecordText: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        if let pdm = patientDataManager {
            healthRecordText.text = pdm.serverRecords
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
