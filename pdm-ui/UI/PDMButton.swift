//
//  PDMButton.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import UIKit


// All this does is customize a few parts of the UI button to provide a consistent look and feel.
@IBDesignable
class PDMButton: UIButton {
    @IBInspectable var pdmButtonActive = true {
        didSet {
            updateStyle()
        }
    }

    override var isEnabled: Bool {
        didSet(value) {
            updateStyle()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButtonStyle()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupButtonStyle()
    }

    override func prepareForInterfaceBuilder() {
        setupButtonStyle()
    }

    internal func setupButtonStyle() {
        layer.cornerRadius = 8
        contentEdgeInsets.left = 10
        contentEdgeInsets.top = 10
        contentEdgeInsets.right = 10
        contentEdgeInsets.bottom = 10
        updateStyle()
    }

    internal func updateStyle() {
        if pdmButtonActive {
            backgroundColor = isEnabled ? PDMTheme.activeBackgroundColor : PDMTheme.disabledActiveBackgroundColor
            tintColor = isEnabled ? PDMTheme.activeTintColor : PDMTheme.disabledActiveTintColor
        } else {
            backgroundColor = PDMTheme.basicBackgroundColor
            tintColor = PDMTheme.basicTintColor
        }
    }
}
