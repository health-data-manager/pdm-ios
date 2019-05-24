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
    /// Boxes that only exist for demo purposes. THIS WILL BE REMOVED WHEN ALL DATA COMES FROM THE PDM
    static var demoBoxes = [ [ "title": "Condition", "measurement": "Sinusitis", "style": "condition" ],
                             [ "title": "Cholesterol HDL", "measurement": "53.5", "units": "mg/dL", "style": "lab" ],
                             [ "title": "Triglycerides", "measurement": "86", "units": "mg/dL", "style": "lab" ],
                             [ "title": "BMI-body mass index", "measurement": "26", "units": "kg/m\u{B2}", "style": "vital" ]
    ]

    @IBOutlet weak var webView: WKWebView!
    var patientViewNavigation: WKNavigation?
    var patientURL: URL?

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
        var boxes = [[String: String]]()
        var careplan = [
            "header": "Go for a 15 minute jog or bike ride",
            "body": "Regular exercise decreases your risk of developing certain diseases, including type 2 diabetes or high blood pressure."
        ]
        // See if we can find a cancer resource
        if let pdm = patientDataManager {
            if let records = pdm.serverRecords {
                let cancerResources = records.search([
                    "meta": [
                        "profile": [
                            "http://hl7.org/fhir/us/shr/StructureDefinition/onco-core-PrimaryCancerCondition"
                        ]
                    ]
                ])
                // For now, just use the first one
                if let cancerResource = cancerResources.first, let cancerType = cancerResource.getString(forField: "code.text") {
                    var box = [ "title": "Cancer", "measurement": cancerType, "style": "disease" ]
                    if let cancerStageCoding = cancerResource.getValue(forField: "stage.summary.coding") as? [Any],
                        let cancerStageElement = cancerStageCoding.first,
                        let cancerStageCodingObj = cancerStageElement as? [String: Any],
                        let cancerStage = cancerStageCodingObj["display"] as? String {
                            box["title"] = cancerStage
                    }
                    boxes.append(box)
                    // Change careplan to a cancer careplan
                    careplan["title"] = "Colon Cancer Care Plan"
                    careplan["header"] = "Prepare for treatment discussion"
                    careplan["body"] = "Here are some examples of the types of questions you may want to ask Dr. Rusk99 on 21.May, 10AM."
                    careplan["link"] = "pdm://careplan/colonCancer"
                    // Add some more static boxes
                    boxes.append([
                        "title": "Next Appointment with Dr. Rusk99",
                        "measurement": "21.May",
                        "delta": "10:00AM",
                        "style": "appointment"
                    ])
                    boxes.append([
                        "title": "Patient Data Receipt from Dr. Rusk99",
                        "measurement": "Routine Visit",
                        "link": "pdm://health-receipt/1",
                        "style": "health-receipt"
                    ])
                }
            }
        }
        // Add in demo boxes as necessary
        boxes.append(contentsOf: PatientHealthRecordViewController.demoBoxes[0...(3-boxes.count)])
        do {
            let json = try JSONSerialization.data(withJSONObject: [ "careplan": careplan, "boxes": boxes, "colors": generateColorJSON() ], options: [])
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
