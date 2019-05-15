//
//  PatientHealthRecordViewController.swift
//  pdm-ui
//
//  Created by Potter, Dan on 5/2/19.
//  Copyright © 2019 MITRE. All rights reserved.
//

import UIKit
import WebKit

class PatientHealthRecordViewController: UIViewController {

    @IBOutlet weak var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // For prototyping purposes, it makes more sense to implement this as HTML
        // Eventually as much as possible should be done via native controls, but for rapid prototyping, do as HTML
        guard let patientURL = Bundle.main.url(forResource: "patient", withExtension: "html") else {
            webView.loadHTMLString("<html><body>Could not load patient view</body></html>", baseURL: nil)
            return
        }
        webView.loadFileURL(patientURL, allowingReadAccessTo: patientURL)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
