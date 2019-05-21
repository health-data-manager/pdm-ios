//
//  PDMTheme.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import UIKit

extension UIColor {
    var htmlColor: String {
        // Grab the color components as RGB
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        // HTML only supports integers
        return "rgba(\(Int(red * 255.0)), \(Int(green * 255.0)), \(Int(blue * 255.0)), \(alpha))"
    }
}

// Contains static information about the PDM "theme" (for consistent colors and the like)
class PDMTheme {
    static let activeBackgroundColor = UIColor(named: "SelectedNav") ?? UIColor.blue
    static let activeTintColor = UIColor.white
    static let disabledActiveBackgroundColor = (UIColor(named: "SelectedNav") ?? UIColor.blue).withAlphaComponent(0.25)
    static let disabledActiveTintColor = UIColor.black
    static let basicBackgroundColor = UIColor.clear
    static let basicTintColor = UIColor(named: "UnselectedNav") ?? UIColor.gray
}
