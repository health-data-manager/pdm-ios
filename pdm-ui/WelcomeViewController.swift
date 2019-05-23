//
//  WelcomeViewController.swift
//  pdm-ui
//
//  Created by Potter, Dan on 4/17/19.
//  Copyright © 2019 MITRE. All rights reserved.
//

import UIKit

class WelcomeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    // MARK: - Navigation

    override func viewDidAppear(_ animated: Bool) {
        if let navigationController = navigationController {
            navigationController.setNavigationBarHidden(true, animated: animated)
        }
        guard let pdm = patientDataManager else { return }
        if pdm.autoLogin {
            do {
                try pdm.signInAsUserFromKeychain() { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            // This error indicate a "real" error
                            self.presentErrorAlert(error, title: "Could not login")
                        } else {
                            // If we succeeded, segue immediately to the main screen
                            self.performSegue(withIdentifier: "LoggedIn", sender: self)
                        }
                    }
                }
            } catch KeychainError.noPassword {
                // This is a non-error error, it means no password was stored and we should proceed as normal
            } catch {
                // This is a "real" error
                presentErrorAlert(error, title: "Could not restore login")
            }
        }
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        // Always reenable the navigation bar
        if let navigationController = navigationController {
            navigationController.setNavigationBarHidden(false, animated: true)
        }
    }

}
