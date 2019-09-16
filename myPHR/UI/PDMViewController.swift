//
//  PDMViewController.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import UIKit

// This adds some helpers to ViewControllers.

extension UIViewController {
    // Helper for getting the PatientDataManager singleton
    var patientDataManager: PatientDataManager? {
        guard let app = UIApplication.shared.delegate as? AppDelegate,
            let pdm = app.patientDataManager else {
                return nil
        }
        return pdm
    }

    // Very basic function to show a very simple alert.
    func presentAlert(_ message: String, title: String?, dismissLabel: String="OK", completionHandler: (() -> Void)?=nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: dismissLabel, style: .default)
        alert.addAction(defaultAction)
        present(alert, animated: true, completion: completionHandler)
    }

    /**
     Generates a loading alert, but does not present it. At present this returns a UIViewController, a future version might make this a more specific version.

     - Parameter message: the message to display while loading
     - Returns: a view controller that displays an activity indicator
     */
    func createLoadingAlert(_ message: String) -> UIViewController {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.style = .gray
        loadingIndicator.startAnimating()
        alert.view.addSubview(loadingIndicator)
        return alert
    }

    /**
     Helper function to present an error alert. This may be called from any thread - if not called from the main thread, this will be dispatched to the main queue.

     - Parameters:
         - error: the error to display
         - title: the title to display, may be nil to not include a title
         - dismissLabel: the text to display on the dismiss button, defaults to OK
     */
    func presentErrorAlert(_ error: Error, title: String?, dismissLabel: String="OK") {
        // Go ahead and decode the message in whatever thread we're in
        var message: String?
        if let pdmError = error as? PatientDataManagerError {
            switch(pdmError) {
            case .formInvalid(let errors):
                var m = "Form fields contained errors:\n"
                for (field, fieldErrors) in errors {
                    if fieldErrors.isEmpty {
                        m.append(" - \(field) contains unspecified errors\n")
                    } else if fieldErrors.count == 1 {
                        m.append(" - \(field): \(fieldErrors[0])\n")
                    } else {
                        m.append(" - \(field):\n")
                        for fieldError in fieldErrors {
                            m.append("     - \(fieldError)\n")
                        }
                    }
                }
                print("Decoded errors to \(m)")
                message = m
            default:
                message = pdmError.localizedDescription
            }
        } else if let restError = error as? RESTError {
            message = restError.localizedDescription
        } else {
            message = "An error occurred: \(error.localizedDescription)"
        }
        // And now that we have it:
        let nonOptionalMessage = message ?? "An unknown error occurred."
        if Thread.isMainThread {
            presentAlert(nonOptionalMessage, title: title, dismissLabel: dismissLabel)
        } else {
            DispatchQueue.main.async {
                self.presentAlert(nonOptionalMessage, title: title, dismissLabel: dismissLabel)
            }
        }
    }
}
