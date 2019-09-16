//
//  ViewController.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import UIKit

// Displays a login view.
class LoginViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signInButton: PDMButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        updateButtonState()
    }

    @IBAction func loginPressed(_ sender: Any) {
        startLogin()
    }

    @IBAction func emailDone(_ sender: Any) {
        passwordTextField.becomeFirstResponder()
    }

    @IBAction func emailChanged(_ sender: Any) {
        updateButtonState()
    }

    @IBAction func passwordChanged(_ sender: Any) {
        updateButtonState()
    }

    func updateButtonState() {
        let email = emailTextField.text ?? ""
        let password = passwordTextField.text ?? ""
        signInButton.isEnabled = !(email.isEmpty || password.isEmpty)
    }

    @IBAction func passwordDone(_ sender: Any) {
        if signInButton.isEnabled {
            startLogin()
        }
    }

    func startLogin() {
        // For now, display the progress indicator and wait...
        // Grab the app delegate
        guard let pdm = patientDataManager,
            let email = emailTextField.text,
            let password = passwordTextField.text else {
                return
        }
        let alert = createLoadingAlert("Signing into PDM...")
        // The login can happen quickly enough that the animation hasn't had time to complete, and we need it to complete before we can remove the alert
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        present(alert, animated: true, completion: {
            dispatchGroup.leave()
        })
        pdm.signInAsUser(email: email, password: password, completionHandler: { (error: Error?) in
            // Because we may be waiting on the animation, add this to the block
            dispatchGroup.notify(queue: DispatchQueue.main, execute: {
                self.dismiss(animated: false) {
                    if let error = error {
                        self.presentErrorAlert(error, title: "Error Logging In")
                    } else {
                        self.loginCompleted()
                    }
                }
            })
        })
    }

    func loginCompleted() {
        // TODO: Make persisting credentials optional based on user settings
        if let pdm = patientDataManager {
            if pdm.autoLogin,
                let email = emailTextField.text,
                let password = passwordTextField.text {
                    do {
                        try pdm.storeCredentialsInKeychain(PDMCredentials(username: email, password: password))
                    } catch {
                        print("Could not persist user credentials to keychain")
                    }
            }
        }
        performSegue(withIdentifier: "Login", sender: self)
    }
}

