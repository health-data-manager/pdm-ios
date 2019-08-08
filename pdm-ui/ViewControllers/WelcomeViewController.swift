//
//  WelcomeViewController.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import UIKit

// This page handles the initial view where the user can be prompted to sign up or log in.
// TODO: If the user has already logged in, it should immediately forward to that part.
class WelcomeViewController: UIViewController {

    @IBOutlet weak var getStartedButton: UIButton!
    @IBOutlet weak var signInButton: UIButton!

    var dataUseAgreement: DataUseAgreement?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        // Disable the get started button while loading.
        // TODO: Add a loading indicator somewhere?
        getStartedButton.isEnabled = false
        if let url = Bundle.main.url(forResource: "dua", withExtension: "json") {
            DataUseAgreement.load(from: url, callback: { (dua, error) -> Void in
                if let error = error {
                    print("Error loading DUA: \(error)")
                    // TODO: Show this error somehow
                } else {
                    self.dataUseAgreement = dua
                    DispatchQueue.main.async { self.getStartedButton.isEnabled = true }
                }
            })
        } else {
            print("Cannot find dua.json")
        }
    }

    // MARK: - Navigation

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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

        switch (segue.identifier ?? "") {
        case "GetStarted":
            guard let dataUseAgreementView = segue.destination as? DataUseAgreementViewController else {
                fatalError("Segueing to unknown class \(segue.destination)")
            }
            dataUseAgreementView.dataUseAgreement = dataUseAgreement
        case "SignIn":
            // Nothing to do at this point
            break
        default:
            fatalError("Unexpected segue: \(String(describing: segue.identifier))")
        }
    }

}
