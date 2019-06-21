//
//  PDMTheme.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import UIKit

extension UIColor {
    /// Converts this UIColor into a CSS color (like `rgba()`)
    var cssColor: String {
        // Grab the color components as RGB
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        // HTML only supports integers
        let redInt = Int(red * 255.0), greenInt = Int(green * 255.0), blueInt = Int(blue * 255.0)
        if alpha < 1.0 {
            return "rgba(\(redInt), \(greenInt), \(blueInt), \(alpha))"
        } else {
            return "rgb(\(redInt), \(greenInt), \(blueInt))"
        }
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
    static let basicBorderColor = UIColor(named: "UnselectedNav") ?? UIColor.gray
    static let basicBorderedTintColor = UIColor.black
}
