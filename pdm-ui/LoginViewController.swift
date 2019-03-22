//
//  ViewController.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import UIKit

// Displays a login view.
class LoginViewController: UIViewController {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func loginPressed(_ sender: Any) {
        startLogin()
    }

    func startLogin() {
        // For now, display the progress indicator and wait...
        activityIndicator.startAnimating()
        // Grab the app delegate
        if let app = UIApplication.shared.delegate as? AppDelegate {
            if let pdm = app.patientDataManager {
                pdm.clientLogin(completionHandler: { (error: Error?) -> Void in
                    DispatchQueue.main.async {
                        if (error != nil) {
                            print("An error occurred.")
                        } else {
                            self.loginCompleted()
                        }
                    }
                })
            }
        }
    }

    func loginCompleted() {
        activityIndicator.stopAnimating()
        performSegue(withIdentifier: "Login", sender: self)
    }
}

