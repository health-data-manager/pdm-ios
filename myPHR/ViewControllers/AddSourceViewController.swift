//
//  AddSourceViewController.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import UIKit

/// View controller for adding a single source.
class AddSourceViewController: UIViewController {
    var provider: PDMProvider?
    @IBOutlet weak var providerImageView: UIImageView!
    @IBOutlet weak var connectProviderButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if let provider = provider {
            if let logo = provider.logo, let image = UIImage(data: logo) {
                providerImageView.image = image
                providerImageView.isHidden = false
            } else {
                providerImageView.isHidden = true
            }
            // Create an NSAttributedString to hold the text describing the provider
            let size: CGFloat = 17.0
            let providerDescription = NSMutableAttributedString(string: provider.name, attributes: [.font: UIFont.boldSystemFont(ofSize: size)])
            if !provider.description.isEmpty {
                providerDescription.append(NSAttributedString(string: "\n\(provider.description)", attributes: [.font: UIFont.systemFont(ofSize: size)]))
            }
            connectProviderButton.setAttributedTitle(providerDescription, for: .normal)
        } else {
            connectProviderButton.setTitle("Error: no provider defined", for: .normal)
        }
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "Connect" {
            guard let oauthViewController = segue.destination as? AddSourceOAuthViewController else {
                // Maybe should be a fatal error?
                return
            }
            oauthViewController.provider = provider
        }
    }

}
