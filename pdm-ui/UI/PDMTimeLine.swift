//
//  PDMTimeLine.swift
//  pdm-ui
//
//  Created by Potter, Dan on 5/21/19.
//  Copyright © 2019 MITRE. All rights reserved.
//

import UIKit

/// Simple view for displaying the time line down the side of a careplan.
@IBDesignable class PDMTimeLine: UIView {
    @IBInspectable var pipColor = UIColor.darkGray
    @IBInspectable var lineColor = UIColor.lightGray
    @IBInspectable var pipSize = CGFloat(10)
    @IBInspectable var lineWidth = CGFloat(4)

    override var intrinsicContentSize: CGSize {
        // Essentially the basic size is the size of the pip.
        return CGSize(width: pipSize, height: pipSize)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    override func prepareForInterfaceBuilder() {
        setup()
    }

    internal func setup() {
        // Currently there is no setup
    }

    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        if let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(lineColor.cgColor)
            context.fill(CGRect(x: (bounds.width - lineWidth) / 2 + bounds.minX, y: bounds.minY, width: lineWidth, height: bounds.height))
            context.setFillColor(pipColor.cgColor)
            context.fillEllipse(in: CGRect(x: (bounds.width - pipSize) / 2 + bounds.minX, y: bounds.minY, width: pipSize, height: pipSize))
        }
    }

}
