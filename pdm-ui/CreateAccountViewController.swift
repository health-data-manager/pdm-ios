//
//  CreateAccountViewController.swift
//  pdm-ui
//
//  Created by Potter, Dan on 4/29/19.
//  Copyright © 2019 MITRE. All rights reserved.
//

import UIKit

class CreateAccountViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet weak var firstNameField: UITextField!
    @IBOutlet weak var lastNameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var passwordConfirmationField: UITextField!
    @IBOutlet weak var createAccountButton: PDMButton!
    @IBOutlet weak var passwordStatusLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        updateCreateAccountButtonState()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: - Actions
    @IBAction func nextButtonTriggered(_ sender: Any) {
        // Check who the sender is and focus based on that
        if let field = sender as? UITextField {
            var nextField: UITextField?
            if field == firstNameField {
                nextField = lastNameField
            } else if field == lastNameField {
                nextField = emailField
            } else if field == emailField {
                nextField = passwordField
            } else if field == passwordField {
                nextField = passwordConfirmationField
            } else if field == passwordConfirmationField {
                // Go ahead and create the account in this case
                createAccount()
                return
            }
            if let nextField = nextField {
                nextField.becomeFirstResponder()
            }
        }
    }

    @IBAction func editingChanged(_ sender: Any) {
        // For now just check to make sure
        updateCreateAccountButtonState()
        if let sendingField = sender as? UITextField {
            if sendingField == passwordField || sendingField == passwordConfirmationField {
                if passwordField.isEmpty {
                    passwordStatusLabel.text = "Password not filled in yet"
                    passwordStatusLabel.textColor = UIColor.black
                } else {
                    if let password = passwordField.text, let passwordConfirmation = passwordConfirmationField.text {
                        if password == passwordConfirmation {
                            passwordStatusLabel.text = "\u{2714}\u{FE0E} Passwords match"
                            passwordStatusLabel.textColor = UIColor.green
                        } else {
                            passwordStatusLabel.text = "Passwords do not match"
                            passwordStatusLabel.textColor = UIColor.red
                        }
                    } else {
                        passwordStatusLabel.text = "Password could not be read"
                        passwordStatusLabel.textColor = UIColor.red
                    }
                }
            }
        }
    }

    @IBAction func createAccountTriggered(_ sender: Any) {
        createAccount()
    }

    func updateCreateAccountButtonState() {
        createAccountButton.isEnabled = !(firstNameField.isEmpty || lastNameField.isEmpty || emailField.isEmpty || passwordField.isEmpty || passwordConfirmationField.isEmpty)
    }

    // Submit the current fields to create an account (if possible).
    func createAccount() {
        guard let pdm = patientDataManager else {
            presentAlert("No patient data manager", title: "nil")
            return
        }
        guard let password = passwordField.text, let passwordConfirmation = passwordConfirmationField.text else {
            // In this case, one of the two is blank, probably
            print("A password was nil")
            return
        }
        guard password == passwordConfirmation else {
            presentAlert("The password and the password confirmation field do not match.", title: "Passwords do not match")
            return
        }
        guard let firstName = firstNameField.text,
            let lastName = lastNameField.text,
            let email = emailField.text else {
                presentAlert("Missing fields", title: nil)
                return
        }
        let alert = createLoadingAlert("Creating PDM account...")
        // The HTTP request can happen quickly enough that the animation hasn't had time to complete, and we need it to complete before we can remove the alert
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        present(alert, animated: true, completion: {
            dispatchGroup.leave()
        })
        pdm.createNewUserAccount(firstName: firstName, lastName: lastName, email: email, password: password, passwordConfirmation: passwordConfirmation) { (user, error) in
            dispatchGroup.notify(queue: DispatchQueue.main) {
                if let error = error {
                    self.dismiss(animated: false) {
                        self.presentErrorAlert(error, title: "Error creating account")
                    }
                } else if user == nil {
                    self.dismiss(animated: false) {
                        self.presentAlert("Did not receive a user from the server.", title: "Error creating account")
                    }
                } else {
                    self.loginWithNewAccount(email: email, password: password)
                }
            }
        }
    }

    func loginWithNewAccount(email: String, password: String) {
        guard let pdm = patientDataManager else {
            presentAlert("No patient data manager", title: "nil")
            return
        }
        pdm.signInAsUser(email: email, password: password) { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.dismiss(animated: false) {
                        self.presentErrorAlert(error, title: "Error logging in to new account")
                    }
                } else {
                    // Looks all good
                    self.dismiss(animated: true) {
                        self.accountCreated()
                    }
                }
            }
        }
    }

    func accountCreated() {
        // Once the account was created, we can then log in using the credentials
        // Segue to the main UI
        performSegue(withIdentifier: "AccountCreated", sender: self)
    }
}
