//
//  AccountInfoViewController.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import UIKit

class AccountInfoViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func logOutAction(_ sender: UIButton) {
        guard let pdm = patientDataManager else {
            // Should raise an error?
            return
        }
        // Ensure autologin is disabled or this will get interesting
        pdm.autoLogin = false
        pdm.signOut() { error in
            if let error = error {
                self.presentErrorAlert(error, title: "Error Logging Out")
            } else {
                DispatchQueue.main.async {
                    // And kill EVERYTHING - this completely resets the root controller, blanking out everything
                    let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
                    UIApplication.shared.keyWindow?.rootViewController = mainStoryboard.instantiateInitialViewController()
                }
            }
        }
    }
}
