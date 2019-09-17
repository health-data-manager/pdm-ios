//
//  PDMButton.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import UIKit

/// A button with a solid background color and rounded corners.
@IBDesignable
class PDMButton: UIButton {
    // In order for IBInspectable Swift properties to show up in IB, they must be computed properties.
    private var _buttonActive = true
    private var _buttonBordered = false

    @IBInspectable var isButtonActive: Bool {
        get {
            return _buttonActive
        }
        set {
            _buttonActive = newValue
            updateStyle()
        }
    }
    @IBInspectable var isButtonBordered: Bool {
        get {
            return _buttonBordered
        }
        set {
            _buttonBordered = newValue
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
        // When initially creating the button, make the font bold
        if let titleLabel = titleLabel {
            titleLabel.font = UIFont.boldSystemFont(ofSize: 15.0)
        }
        updateStyle()
    }

    internal func updateStyle() {
        if _buttonActive {
            backgroundColor = isEnabled ? PDMTheme.activeBackgroundColor : PDMTheme.disabledActiveBackgroundColor
            tintColor = isEnabled ? PDMTheme.activeTintColor : PDMTheme.disabledActiveTintColor
        } else {
            backgroundColor = PDMTheme.basicBackgroundColor
            tintColor = _buttonBordered ? PDMTheme.basicBorderedTintColor : PDMTheme.basicTintColor
        }
        if _buttonBordered {
            layer.borderColor = PDMTheme.basicBorderColor.cgColor
            layer.borderWidth = 1.0
        } else {
            layer.borderColor = nil
            layer.borderWidth = 0.0
        }
    }
}
