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
        guard let app = UIApplication.shared.delegate as? AppDelegate,
            let pdm = app.patientDataManager,
            let email = emailTextField.text,
            let password = passwordTextField.text else {
                return
        }
        let alert = UIAlertController(title: nil, message: "Signing into PDM...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.style = .gray
        loadingIndicator.startAnimating()
        alert.view.addSubview(loadingIndicator)
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
                        // Generate a new alert
                        var message: String?
                        if let pdmError = error as? PatientDataManagerError {
                            switch pdmError {
                            case .loginFailed:
                                message = "Could not sign you into the Patient Data Manager. Please check to make sure your email and password are correct."
                            case .couldNotUnderstandResponse:
                                message = "Could not parse the response from the server."
                            case .serverReturnedError(let statusCode):
                                if (500...599).contains(statusCode) {
                                    message = "The server encountered an error while logging in. (HTTP \(statusCode))"
                                }
                            case .internalError:
                                message = "An internal error occurred before the request could be sent."
                            }
                        } else {
                            message = "An unknown error occurred while logging in."
                        }
                        let loginFailedAlert = UIAlertController(title: "Sign In Failed", message: message, preferredStyle: .alert)
                        loginFailedAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                        }))
                        self.present(loginFailedAlert, animated: true, completion: nil)
                    } else {
                        self.loginCompleted()
                    }
                }
            })
        })
    }

    func loginCompleted() {
        performSegue(withIdentifier: "Login", sender: self)
    }
}

