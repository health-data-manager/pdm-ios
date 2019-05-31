//
//  PatientHealthRecordViewController.swift
//  pdm-ui
//
//  Created by Potter, Dan on 5/2/19.
//  Copyright © 2019 MITRE. All rights reserved.
//

import UIKit
import WebKit

class PatientHealthRecordViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    @IBOutlet weak var webView: WKWebView!
    var patientViewNavigation: WKNavigation?
    var patientURL: URL?
    let recordDataController = PatientHealthRecordDataController()

    override func viewDidLoad() {
        super.viewDidLoad()
        // For prototyping purposes, it makes more sense to implement this as HTML
        // Eventually as much as possible should be done via native controls, but for rapid prototyping, do as HTML
        guard let patientURL = Bundle.main.url(forResource: "patient", withExtension: "html") else {
            webView.loadHTMLString("<html><body>Could not load patient view</body></html>", baseURL: nil)
            return
        }
        self.patientURL = patientURL
        webView.navigationDelegate = self
        webView.uiDelegate = self
        patientViewNavigation = webView.loadFileURL(patientURL, allowingReadAccessTo: patientURL)
    }

    func displayPatientData() {
        guard let pdm = patientDataManager, let records = pdm.serverRecords else {
            // There's nothing to show
            return
        }
        let tiles = recordDataController.calculatePatientData(fromRecords: records)
        let careplan = recordDataController.calculateCarePlan(fromRecords: records)
        let tilesJSON = tiles.map({ tile in return tile.jsonValue() })
        do {
            let json = try JSONSerialization.data(withJSONObject: [ "careplan": careplan.jsonValue(), "tiles": tilesJSON, "colors": generateColorJSON() ], options: [])
            guard let jsonString = String(data: json, encoding: .utf8) else {
                // TODO: Show an error somewhere? This shouldn't be possible
                return
            }
            webView.evaluateJavaScript("setup(\(jsonString))") { result, error in
                if let error = error {
                    print("Error while setting up patient view: \(error)")
                }
            }
        } catch {
            // TODO: Log this error somewhere
        }
    }

    func generateColorJSON() -> [String: Any] {
        var result = [String: Any]()
        for type in PDMRecordType.allCases {
            if let color = UIColor(named: type.name) {
                result[type.cssName] = color.cssColor
            }
        }
        return result
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    func openInternalURL(_ url: URL) {
        // Ignore the scheme for this
        // Host is the type for now
        if let type = url.host {
            if type == "careplan" {
                performSegue(withIdentifier: "CarePlan", sender: self)
            } else if type == "health-receipt" {
                performSegue(withIdentifier: "HealthReceipt", sender: self)
            }
        }
    }

    // MARK: - WK Navigation Delegate
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if navigation == patientViewNavigation {
            // No longer need the navigation
            patientViewNavigation = nil
            displayPatientData()
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.request.url == patientURL {
            // Always allow navigations to ourself
            decisionHandler(.allow)
            return
        }
        if let requestURL = navigationAction.request.url, let scheme = requestURL.scheme, scheme.caseInsensitiveCompare("pdm") == .orderedSame {
            openInternalURL(requestURL)
            decisionHandler(.cancel)
            return
        }
        switch navigationAction.navigationType {
        case .linkActivated:
            // If the link is to an HTTP/HTTPS link, forward to Safari
            if let url = navigationAction.request.url, let scheme = url.scheme {
                if scheme.caseInsensitiveCompare("http") == .orderedSame || scheme.caseInsensitiveCompare("https") == .orderedSame {
                    UIApplication.shared.open(url)
                }
            }
            // In any case, cancel this
            decisionHandler(.cancel)
        case .formSubmitted, .formResubmitted:
            // For now, disallow in these scenarios
            decisionHandler(.cancel)
        case .backForward, .reload, .other:
            decisionHandler(.allow)
        @unknown default:
            decisionHandler(.cancel)
        }
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let okAction = UIAlertAction(title: "OK", style: .default) { alert in
            completionHandler()
        }
        let alert = UIAlertController(title: "JavaScript Alert", message: message, preferredStyle: .alert)
        alert.addAction(okAction)
        present(alert, animated: true)
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let okAction = UIAlertAction(title: "OK", style: .default) { alert in
            completionHandler(true)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { alert in
            completionHandler(false)
        }
        let alert = UIAlertController(title: "JavaScript Alert", message: message, preferredStyle: .alert)
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
}
