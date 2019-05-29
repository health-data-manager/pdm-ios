//
//  PDMMiniBrowserViewController.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import UIKit
import WebKit

/**
 Provides implementations of a bunch of standard WKUIDelegate functions.
 */
class PDMMiniBrowserViewController: UIViewController, WKUIDelegate {
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: "JavaScript Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { alert in
            completionHandler()
        })
        present(alert, animated: true)
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: "JavaScript Confirm", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { alert in
            completionHandler(true)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { alert in
            completionHandler(false)
        })
        present(alert, animated: true)
    }

    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let alert = UIAlertController(title: "JavaScript Input", message: prompt, preferredStyle: .alert)
        alert.addTextField() { textField in
            textField.text = defaultText
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default) { action in
            guard let textField = alert.textFields?[0] else {
                completionHandler(nil)
                return
            }
            completionHandler(textField.text)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { alert in
            completionHandler(nil)
        })
        present(alert, animated: true)
    }

    /// Helper func for generating an error page
    func loadErrorPageIn(_ webView: WKWebView, message: String) {
        webView.loadHTMLString("""
<!DOCTYPE html>
<html>
<head><title>Error</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style type="text/css">
html { font-family: -apple-system; font-size: 17px; }
</style>
</head>
<body>
<h1>Error Loading Page</h1>
<p>An error occured.</p>
</body></html>
""", baseURL: nil)
    }
}
