//
//  PDMCheckbox.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import UIKit

// Provides a checkbox control (used for the digital signature page right now).
// This doesn't really work quite correctly but it works well enough for now.
@IBDesignable
class PDMCheckbox: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupButton()
    }

    override func prepareForInterfaceBuilder() {
        setupButton()
    }

    internal func setupButton() {
        addTarget(self, action: #selector(PDMCheckbox.toggleCheckbox), for: .primaryActionTriggered)
        setTitle("\u{2610}", for: .normal)
        setTitle("\u{2611}\u{FE0E}", for: .selected)
    }

    @objc func toggleCheckbox() {
        self.isSelected = !self.isSelected
    }
}
