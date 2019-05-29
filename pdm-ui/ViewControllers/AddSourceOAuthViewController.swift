//
//  AddSourceOAuthViewController.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import UIKit
import WebKit
import os.log

/// Handles the OAuth step.
class AddSourceOAuthViewController: PDMMiniBrowserViewController, WKNavigationDelegate {
    /// The fake URI used to redirect back to this system when OAuth completes
    static var redirectHost = "patient-data-manager.local"
    var provider: PDMProvider?
    var initialNavigation: WKNavigation?

    @IBOutlet weak var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        webView.navigationDelegate = self
        webView.uiDelegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startConnectingToProvider()
    }

    private func startConnectingToProvider() {
        // Start the web view loading the request to handle this
        guard let pdm = patientDataManager, let provider = provider else {
            // TODO: Should be a fatal error?
            os_log(.error, "Missing required data")
            return
        }
        navigationItem.title = "Loading..."
        // Start loading the data
        pdm.linkToProvider(provider, redirectURI: "https://\(AddSourceOAuthViewController.redirectHost)/") { url, error in
            if let error = error {
                self.presentErrorAlert(error, title: "Unable to get URL")
                return
            }
            guard let url = url else {
                os_log(.error, "Did not get OAuth URL back")
                return
            }
            DispatchQueue.main.async {
                print("Loading \(url)...")
                self.initialNavigation = self.webView.load(URLRequest(url: url))
            }
        }
    }

    private func handleCallback(_ url: URL) {
        // Convert to URLComponents
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false), let queryItems = components.queryItems else {
            presentAlert("Could not understand response", title: "Error")
            return
        }
        var code: String?
        for queryItem in queryItems {
            if queryItem.name == "code", let value = queryItem.value {
                // Found the code
                code = value
            }
        }
        guard let oauthCode = code else {
            presentAlert("Missing code from Oauth response", title: "Error")
            return
        }
        guard let pdm = patientDataManager, let provider = provider else {
            return
        }
        let group = DispatchGroup()
        group.enter()
        present(createLoadingAlert("Linking to profile..."), animated: true) {
            group.leave()
        }
        pdm.linkToProviderOauthCallback(provider, code: oauthCode, redirectURI: "https://\(AddSourceOAuthViewController.redirectHost)/") { error in
            // Make sure we do this after the animation has finished
            group.notify(queue: DispatchQueue.main) {
                if let error = error {
                    self.dismiss(animated: false) {
                        self.presentErrorAlert(error, title: "Could not link provider")
                    }
                } else {
                    // Dismiss the loading overlay and then dismiss the navigation controller - this resets back to the sources view
                    self.dismiss(animated: true) {
                        self.navigationController?.dismiss(animated: true)
                    }
                }
            }
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

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("Starting nativagtion...")
    }

    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        print("Redirecting...")
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        showNavigationError(error)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showNavigationError(error)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // On the initial navigation, reset the title
        if initialNavigation != nil && navigation == initialNavigation {
            if let provider = provider {
                navigationItem.title = "Connect to \(provider.name)"
            } else {
                navigationItem.title = "Connect"
            }
            initialNavigation = nil
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // There is only one exception in this case: when we're doing the fake navigation back to the PDM front end.
        if let url = navigationAction.request.url {
            if url.host == AddSourceOAuthViewController.redirectHost {
                DispatchQueue.main.async {
                    self.handleCallback(url)
                }
                decisionHandler(.cancel)
                return
            }
        }
        decisionHandler(.allow)
    }

    private func showNavigationError(_ error: Error) {
        navigationItem.title = "Error Loading Page"
        presentErrorAlert(error, title: "Error Loading Page")
        loadErrorPageIn(webView, message: error.localizedDescription)
    }
}
