//
//  HomeViewController.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import UIKit

/**
 The home view controller.
 */
class HomeViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.selectedIndex = 1
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Load the patient data now
        loadPatientData()
    }

    func loadPatientData() {
        print("Loading patient data...")
        guard let pdm = patientDataManager else {
            presentAlert("Please check the patient data manager configuration. (This is an internal error.)", title: "No patient data manager")
            return
        }
        let group = DispatchGroup()
        group.enter()
        present(createLoadingAlert("Loading..."), animated: true) {
            group.leave()
        }
        /*
        pdm.getUserInformation() { (user, error) in
            if let error = error {
                group.notify(queue: DispatchQueue.main) {
                    self.dismiss(animated: false) {
                        self.presentErrorAlert(error, title: "Could not load user data")
                    }
                }
            } else {
                // If we have the user, next get the profiles
 */
                pdm.getUserProfiles() { (profiles, error) in
                    if let error = error {
                        group.notify(queue: DispatchQueue.main) {
                            self.dismiss(animated: false) {
                                self.presentErrorAlert(error, title: "Could not load profile data")
                            }
                        }
                    } else {
                        guard let activeProfile = pdm.activeProfile else {
                            // Don't have an active profile
                            self.dismiss(animated: false) {
                                self.presentAlert("Unable to load a profile for your account. Health information has to be linked to a profile.", title: "Could not load profile data")
                            }
                            return
                        }
                        print("Received profile for \(activeProfile.name)")
                        self.dismiss(animated: true)
                    }
                }
        /*
            }
        }*/
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
