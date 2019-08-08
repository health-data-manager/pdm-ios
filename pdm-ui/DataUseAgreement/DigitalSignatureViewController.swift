//
//  DigitalSignatureViewController.swift
//  pdm-ui
//
//  Created by Potter, Dan on 4/7/19.
//  Copyright © 2019 MITRE. All rights reserved.
//

import UIKit

class DigitalSignatureViewController: UIViewController {

    @IBOutlet weak var agreeButton: UIButton!
    @IBOutlet weak var signatureText: UITextField!
    @IBOutlet weak var agreeCheckbox: PDMCheckbox!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        agreeButton.isEnabled = false
        signatureText.text = ""
    }
    
    @IBAction func signatureEditingChanged(_ sender: Any) {
        updateAgreeAllowed()
    }

    @IBAction func agreeCheckboxTriggered(_ sender: Any) {
        // Also disable editing
        view.endEditing(false)
        updateAgreeAllowed()
    }

    func updateAgreeAllowed() {
        agreeButton.isEnabled = !(signatureText.text?.isEmpty ?? true) && agreeCheckbox.isSelected
    }

    @IBAction func agreeTriggered(_ sender: Any) {
        // When this happens, transition to the login controller
        performSegue(withIdentifier: "CreateAccount", sender: self)
    }

    @IBAction func disagreeTriggered(_ sender: Any) {
        // Currently we just segue back to the main storyboard
        // In the future this may ask the user to confirm they disagree or something
        performSegue(withIdentifier: "Disagree", sender: self)
    }

    @IBAction func signatureEditingDidBegin(_ sender: Any) {
        // When this happens, we should disable navigation keys
        if let duaController = navigationController as? DataUseAgreementViewController {
            duaController.setNavigationKeyControls(enabled: false)
        }
    }

    @IBAction func signatureEditingDidEnd(_ sender: Any) {
        // Once done, navigation keys are "OK" although the next key won't do anything
        if let duaController = navigationController as? DataUseAgreementViewController {
            duaController.setNavigationKeyControls(enabled: true)
        }
    }

    @IBAction func signatureDone(_ sender: Any) {
        // User hit the "done" button
        view.endEditing(false)
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if segue.identifier == "CreateAccount" {
            guard let createAccountViewController = segue.destination as? CreateAccountViewController else {
                fatalError("CreateAccount should segue to a CreateAccountViewController but did not")
            }
            createAccountViewController.legalName = signatureText.text
            createAccountViewController.agreedToDUA = agreeCheckbox.isSelected
        }
    }
}
