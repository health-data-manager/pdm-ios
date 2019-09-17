//
//  TableViewExtensions.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import UIKit

extension UITableView {
    // TODO: Find some way to DRY this out since they're almost identical
    func setEmptyMessage(_ message: NSAttributedString) {
        let messageLabel = UILabel(frame: self.bounds)
        messageLabel.attributedText = message
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.sizeToFit()
        self.backgroundView = messageLabel
        self.separatorStyle = .none
    }
    func setEmptyMessage(_ message: String) {
        let messageLabel = UILabel(frame: self.bounds)
        messageLabel.text = message
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.sizeToFit()
        self.backgroundView = messageLabel
        self.separatorStyle = .none
    }
    func clearEmptyMessage() {
        self.backgroundView = nil
        self.separatorStyle = .singleLine
    }
}
