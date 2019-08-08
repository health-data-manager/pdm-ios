//
//  LegalDetailsViewController.swift
//  pdm-ui
//
//  Created by Potter, Dan on 4/16/19.
//  Copyright © 2019 MITRE. All rights reserved.
//

import UIKit
import WebKit

class LegalDetailsViewController: UIViewController, WKNavigationDelegate {
    var dataUseAgreement: DataUseAgreement? {
        didSet {
            loadDataUseAgreement()
        }
    }
    var page: DataUseAgreementPage? {
        didSet {
            updateHighlightForPage()
        }
    }
    @IBOutlet weak var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        webView.navigationDelegate = self
        if dataUseAgreement != nil {
            loadDataUseAgreement()
        } else {
            print("Not loading DUA (no DUA given)")
        }
        navigationItem.hidesBackButton = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(LegalDetailsViewController.done))
    }

    @objc func done() {
        navigationController?.popViewController(animated: true)
    }

    func loadDataUseAgreement() {
        if let dua = dataUseAgreement, webView != nil {
            print("Loading DUA from \(dua.agreementURL)")
            webView.loadFileURL(dua.agreementURL, allowingReadAccessTo: dua.baseURL)
        }
    }

    func updateHighlightForPage() {
        if let page = page, let legal = page.legal {
            var script = "highlightSection("
            var first = true
            for section in legal {
                if first {
                    first = false
                } else {
                    script.append(", ")
                }
                script.append("\"\(section.addingJavaScriptEscapes())\"")
            }
            script.append(")")
            webView.evaluateJavaScript(script)
        } else {
            // It's also valid (as of now) to request this with no associated information
            webView.evaluateJavaScript("highlightSection([])")
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

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let dua = dataUseAgreement, navigationAction.request.url == dua.agreementURL {
            // Always allow requests to load our own data
            decisionHandler(.allow)
            return
        }
        switch navigationAction.navigationType {
        case .backForward, .reload:
            decisionHandler(.allow)
        case .formSubmitted, .formResubmitted, .linkActivated, .other:
            // If the link was to an HTTP/HTTPS page, pass off to Safari
            if let url = navigationAction.request.url {
                if let scheme = url.scheme {
                    if scheme.caseInsensitiveCompare("http") == .orderedSame || scheme.caseInsensitiveCompare("https") == .orderedSame {
                        UIApplication.shared.open(url)
                    }
                }
            }
            fallthrough
        @unknown default:
            decisionHandler(.cancel)
        }
    }
}
