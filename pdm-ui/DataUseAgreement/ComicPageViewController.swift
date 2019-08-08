//
//  ComicPageViewController.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import UIKit

// Shows a single page in the data use agreement introduction
class ComicPageViewController: UIViewController {
    var page: DataUseAgreementPage?
    var pageNumber: Int?
    var image: UIImage?
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var nextButton: PDMButton!
    @IBOutlet weak var errorLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        if let page = page {
            // We have a page, try and load an image
            loadImage(fromURL: page.image)
            // Also configure the VoiceOver info from it
            if let accessibilityLabel = page.accessibilityLabel {
                imageView.isAccessibilityElement = true
                imageView.accessibilityLabel = accessibilityLabel
                if let hint = page.accessibilityHint {
                    imageView.accessibilityHint = hint
                } else {
                    imageView.accessibilityHint = "Cartoon image"
                }
            } else {
                imageView.isAccessibilityElement = false
            }
            // Add legal info button
            let legalButton = UIBarButtonItem(title: "\u{24D8}", style: .plain, target: self, action: #selector(ComicPageViewController.showLegal))
            legalButton.accessibilityLabel = "Show legal details"
            navigationItem.rightBarButtonItem = legalButton
            if let nextLabel = page.nextLabel {
                nextButton.setTitle(nextLabel, for: .normal)
            }
        }
        if navigationItem.backBarButtonItem == nil {
            print("Back is nil")
        } else {
            print("Back exists")
        }
        if navigationItem.leftBarButtonItem == nil {
            print("Left item is nil")
        } else {
            print("Left item exists")
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        super.prepare(for: segue, sender: sender)
//    }

    func loadImage(fromURL url: URL) {
        let task = URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) -> Void in
            // There's a good chance this will happen off the main UI thread.
            if let error = error {
                print("Unable to load image from \(url): \(error)")
                DispatchQueue.main.async {
                    self.loadImage(withError: error)
                }
                return
            }
            if let data = data {
                DispatchQueue.main.async {
                    self.loadImage(fromData: data)
                }
            }
        })
        progressView.observedProgress = task.progress
        progressView.isHidden = false
        imageView.isHidden = true
        task.resume()
    }

    func loadImage(fromData data: Data) {
        if let image = UIImage(data: data) {
            self.image = image
            progressView.isHidden = true
            imageView.image = image
            imageView.isHidden = false
            // Let the accessibility know that the image is ready and should be read
            UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: imageView)
        }
    }

    func loadImage(withError error: Error) {
        imageView.isHidden = true
        progressView.isHidden = true
        errorLabel.isHidden = false
        errorLabel.text = "Unable to load image: \(error)"
    }

    @IBAction func goToNextPage(_ sender: Any) {
        // Look for our navigation controller and have it handle this
        if let duaController = navigationController as? DataUseAgreementViewController {
            duaController.goToNextPage()
        }
    }

    // Shows whatever legal information is associated with this page (if there is any)
    @objc func showLegal() {
        if let duaController = parent as? DataUseAgreementViewController, let page = page {
            duaController.showLegalDetails(for: page)
        }
    }
}
