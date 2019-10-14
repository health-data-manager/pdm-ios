//
//  PDMBadge.swift
//  myPHR
//
//  Created by Potter, Dan on 9/24/19.
//  Copyright © 2019 MITRE. All rights reserved.
//

import UIKit

/// A PDM Badge. Adds a background behind the label, otherwise identical to a regular label.
class PDMBadge: UILabel {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupStyle()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupStyle()
    }

    override func prepareForInterfaceBuilder() {
        setupStyle()
    }

    internal func setupStyle() {
        layer.cornerRadius = 8
    }

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
