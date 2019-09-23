//
//  PDMTheme.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import UIKit

extension UIColor {
    /// Provides a CSS color (like `rgba()`) version of this UIColor.
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

/// Contains static information about the PDM "theme" (for consistent colors and the like).
///
/// Some notes: background color is the background behind the element, so e.g. the fill for a button. "Tint" color is what UIKit refers to the foreground color as, so e.g. the text color of a button or the color used to "tint" any icons within the element.
class PDMTheme {
    /// The active background color ("SelectedNav" named color, default blue)
    static let activeBackgroundColor = UIColor(named: "SelectedNav") ?? UIColor.blue
    static let activeTintColor = UIColor.white
    /// The disabled active background color (currently the active background desaturated 0.25)
    static let disabledActiveBackgroundColor = (UIColor(named: "SelectedNav") ?? UIColor.blue).withAlphaComponent(0.25)
    static let disabledActiveTintColor = UIColor.black
    /// Background color for most things (currently clear)
    static let basicBackgroundColor = UIColor.clear
    /// Basic tint color for generic (non-active) things (currently gray)
    static let basicTintColor = UIColor(named: "UnselectedNav") ?? UIColor.gray
    /// Basic border color for generic (non-active) things (currently gray)
    static let basicBorderColor = UIColor(named: "UnselectedNav") ?? UIColor.gray
    static let basicBorderedTintColor = UIColor.black

    /// Date format string used for formatting dates
    static let dateFormat = "yyyy.MMM.dd"
    /// Time format string used for formatting times
    static let timeFormat = "HH:mm"

    private static let dateFormatter = { () -> DateFormatter in
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        formatter.timeStyle = .none
        return formatter
    }()

    /// Format the date in a standard app-specific fashion.
    ///
    /// - Parameter date: the date to format
    /// - Returns: the formatted date
    static func formatDate(_ date: Date) -> String {
        // It's unclear to me what the overhead of initializing the date formatter is versus keeping it around.
        return dateFormatter.string(from: date)
    }
}
