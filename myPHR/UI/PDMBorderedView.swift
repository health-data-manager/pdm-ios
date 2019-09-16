//
//  PDMBorderedView.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import UIKit

/// A view with rounded corners.
@IBDesignable
class PDMBorderedView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupStyles()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupStyles()
    }

    override func prepareForInterfaceBuilder() {
        setupStyles()
    }

    internal func setupStyles() {
        // Essentially all we need to do is update our background to add the border and then add some insets
        layer.borderColor = UIColor.gray.cgColor
        layer.borderWidth = 1.0
        layer.cornerRadius = 8.0
    }

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
