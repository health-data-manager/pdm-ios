//
//  AddSourceViewController.swift
//  pdm-ui
//
//  Created by Potter, Dan on 5/23/19.
//  Copyright © 2019 MITRE. All rights reserved.
//

import UIKit

/// View controller for adding a single source.
class AddSourceViewController: UIViewController {
    var provider: PDMProvider?
    @IBOutlet weak var providerImageView: UIImageView!
    @IBOutlet weak var providerDescriptionLabel: UILabel!

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
            providerDescriptionLabel.text = provider.description.isEmpty ? provider.name : provider.description
        } else {
            providerDescriptionLabel.text = "Error: no provider defined"
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

}
