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
        present(alert, animated: true, completion: nil)
        pdm.user(email, signInWithPassword: password, completionHandler: { (error: Error?) -> Void in
            DispatchQueue.main.async {
                self.dismiss(animated: true, completion: nil)
                if (error != nil) {
                    print("An error occurred.")
                } else {
                    self.loginCompleted()
                }
            }
        })
    }

    func loginCompleted() {
        performSegue(withIdentifier: "Login", sender: self)
    }
}

