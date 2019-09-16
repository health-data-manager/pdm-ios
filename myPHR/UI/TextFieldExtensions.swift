//
//  TextFieldExtensions.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import UIKit

extension UITextInput {
    var isEmpty: Bool {
        return self.compare(self.beginningOfDocument, to: self.endOfDocument) == .orderedSame
    }
}
