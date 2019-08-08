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
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var createAccountButton: PDMButton!
    @IBOutlet weak var passwordStatusLabel: UILabel!
    var legalName: String?
    var agreedToDUA: Bool?
    @IBOutlet weak var scrollView: UIScrollView!

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: nil) { notification in
            // Handle keyboard showing
            guard let userInfo = notification.userInfo else { return }
            guard let keyboardInfo = userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue else { return }
            let keyboardSize = keyboardInfo.cgRectValue.size
            let contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardSize.height, right: 0.0)
            self.scrollView.contentInset = contentInsets
            self.scrollView.scrollIndicatorInsets = contentInsets
        }
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: nil) { notification in
            // Handle keyboard hiding
            self.scrollView.contentInset = UIEdgeInsets.zero
            self.scrollView.scrollIndicatorInsets = UIEdgeInsets.zero
        }
        updateCreateAccountButtonState()
        updatePasswordStatus()
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
            if field == emailField {
                nextField = passwordField
            } else if field == passwordField {
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
        if let sendingField = sender as? UITextField, sendingField == passwordField {
            updatePasswordStatus()
        }
    }

    @IBAction func editingDidBegin(_ sender: Any) {
        if let duaController = navigationController as? DataUseAgreementViewController {
            duaController.setNavigationKeyControls(enabled: false)
        }
    }

    @IBAction func editingDidEnd(_ sender: Any) {
        if let duaController = navigationController as? DataUseAgreementViewController {
            duaController.setNavigationKeyControls(enabled: true)
        }
    }

    @IBAction func createAccountTriggered(_ sender: Any) {
        createAccount()
    }

    func updateCreateAccountButtonState() {
        createAccountButton.isEnabled = !(emailField.isEmpty || passwordField.isEmpty)
    }

    func updatePasswordStatus() {
        if passwordField.isEmpty {
            passwordStatusLabel.text = "Password not filled in yet"
            passwordStatusLabel.textColor = UIColor.black
        } else {
            if let password = passwordField.text {
                if password.count < 6 {
                    passwordStatusLabel.text = "Password is too short"
                    passwordStatusLabel.textColor = UIColor.red
                } else {
                    passwordStatusLabel.text = "Password is OK"
                    passwordStatusLabel.textColor = UIColor.green
                }
            } else {
                passwordStatusLabel.text = "Password could not be read"
                passwordStatusLabel.textColor = UIColor.red
            }
        }
    }

    // Submit the current fields to create an account (if possible).
    func createAccount() {
        guard let pdm = patientDataManager else {
            presentAlert("No patient data manager", title: "nil")
            return
        }
        guard let password = passwordField.text else {
            // In this case, one of the two is blank, probably
            return
        }
        guard let legalName = legalName,
            let agreedToDUA = agreedToDUA,
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
        pdm.createNewUserAccount(legalName: legalName, email: email, password: password, acceptedDUA: agreedToDUA) { (user, error) in
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
