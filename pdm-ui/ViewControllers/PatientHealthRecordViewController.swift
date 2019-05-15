//
//  PatientHealthRecordViewController.swift
//  pdm-ui
//
//  Created by Potter, Dan on 5/2/19.
//  Copyright © 2019 MITRE. All rights reserved.
//

import UIKit
import WebKit

class PatientHealthRecordViewController: UIViewController, WKNavigationDelegate {
    @IBOutlet weak var webView: WKWebView!
    var patientViewNavigation: WKNavigation?

    override func viewDidLoad() {
        super.viewDidLoad()
        // For prototyping purposes, it makes more sense to implement this as HTML
        // Eventually as much as possible should be done via native controls, but for rapid prototyping, do as HTML
        guard let patientURL = Bundle.main.url(forResource: "patient", withExtension: "html") else {
            webView.loadHTMLString("<html><body>Could not load patient view</body></html>", baseURL: nil)
            return
        }
        webView.navigationDelegate = self
        patientViewNavigation = webView.loadFileURL(patientURL, allowingReadAccessTo: patientURL)
    }

    func displayPatientData() {
        let boxes = [ [ "title": "Weight", "measurement": "146.5", "units": "lbs", "delta": "-2", "source": "Withings Scale", "style": "vital vital-weight" ],
                      [ "title": "Blood Pressure", "measurement": "108/89", "units": "mmHg", "source": "Mass General Hospital", "style": "vital vital-bp" ],
                      [ "title": "Sleep", "measurement": "6.42", "units": "hours", "source": "iPhone", "style": "vital vital-sleep" ],
                      [ "title": "Mood", "measurement": ":(", "source": "Measure my Mood", "style": "mood" ]
        ]
        do {
            let json = try JSONSerialization.data(withJSONObject: boxes, options: [])
            guard let jsonString = String(data: json, encoding: .utf8) else {
                // TODO: Show an error somewhere? This shouldn't be possible
                return
            }
            webView.evaluateJavaScript("receiveBoxes(\(jsonString))")
        } catch {
            // TODO: Log this error somewhere
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: - WK Navigation Delegate
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("Navigation completed")
        if navigation == patientViewNavigation {
            // No longer need the navigation
            patientViewNavigation = nil
            displayPatientData()
        }
    }
}
