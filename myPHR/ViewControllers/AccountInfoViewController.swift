//
//  AccountInfoViewController.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import UIKit

class AccountInfoViewController: UIViewController {
    @IBOutlet weak var patientAccountImageView: UIImageView!
    @IBOutlet weak var patientNameLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let pdm = patientDataManager, let profile = pdm.activeProfile else {
            // Hrm
            patientNameLabel.text = "No Active Profile"
            patientAccountImageView.isHidden = true
            return
        }
        patientNameLabel.text = profile.name
        // TODO: Load the patient's profile image
        patientAccountImageView.isHidden = true
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func deleteAccountData(_ sender: Any) {
    }
}
