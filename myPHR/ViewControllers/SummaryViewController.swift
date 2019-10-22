//
//  SummaryViewController.swift
//  myPHR
//
//  Created by Potter, Dan on 10/22/19.
//  Copyright © 2019 MITRE. All rights reserved.
//

import UIKit

class SummaryViewController: UIViewController {
    var results: PDMUploadResults?

    @IBOutlet weak var tableViewContainer: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func logOut(_ sender: Any) {
        if let pdm = patientDataManager {
            pdm.signOut() { error in
                // For now error is not possible
                DispatchQueue.main.async {
                    // And kill EVERYTHING - this completely resets the root controller, blanking out everything
                    let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
                    UIApplication.shared.keyWindow?.rootViewController = mainStoryboard.instantiateInitialViewController()
                }
            }
        }
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("Preparing for segue")
        // Embed are "embed segues" so we'll get a segue for the table initializing
        if let tableController = segue.destination as? CategorySummaryTableViewController {
            tableController.uploadResults = results
        }
    }

}
