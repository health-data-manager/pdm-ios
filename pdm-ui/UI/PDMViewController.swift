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
            case .couldNotUnderstandResponse:
                message = "Could not understand response from server."
            case .internalError:
                message = "An internal error occurred while generating the request."
            case .loginFailed:
                message = "Login failed (email and password were not accepted)."
            case .notLoggedIn:
                message = "Request cannot be completed because the client is not logged into the server."
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
            case .noResultFromServer:
                message = "No object was returned by the server."
            }
        } else if let restError = error as? RESTError {
            switch(restError) {
            case .unhandledRedirect:
                message = "The response was redirected to another resource that was not loaded."
            case .unauthorized:
                message = "The server rejected the request because the client is not logged in (may have timed out)."
            case .forbidden:
                message = "Access to the requested resource was forbidden."
            case .missing:
                message = "The requested resource is missing."
            case .serverReturnedError(let statusCode):
                switch(statusCode) {
                case 200..<300:
                    message = "The server returned success but the response could not be handled properly."
                case 300..<400:
                    message = "The server returned a redirect that was not followed."
                case 400:
                    message = "The server could not understand the app's request."
                case 401:
                    message = "The request was not authorized."
                case 403:
                    message = "The server rejected the client request."
                case 404:
                    message = "The server could not find the requested resource."
                case 402, 405..<500:
                    message = "The server could not handle the request."
                case 500:
                    message = "An internal error occurred within the PDM server."
                case 501:
                    message = "The PDM server does not recognize the app's request."
                case 502:
                    message = "The server, or a proxy server prior to the server, could not forward the request to the proper destination."
                case 503:
                    message = "The server could not handle the request at this time."
                case 504:
                    message = "The request timed out before the final server responded."
                default:
                    message = "An HTTP error occurred."
                }
                // Regardless, append the status code to the message
                message?.append(" (HTTP \(statusCode))")
            case .internalError:
                message = "An internal error occurred."
            case .couldNotEncodeRequest(let causedBy):
                if let causedByError = causedBy {
                    message = "Could not encode the request: \(String(describing: causedByError))"
                } else {
                    message = "Could not encode the request"
                }
            case .couldNotParseResponse:
                message = "Could not parse the response"
            case .responseNotJSON:
                message = "Expected JSON from the server but did not receive it"
            case .responseJSONInvalid:
                message = "JSON response from server was not of the expected type"
            }
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
