//
//  HttpExtensions.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//
// A small little library to deal with common HTTP transactions

import Foundation

class MIMEType {
    static let applicationFormEncoded = "application/x-www-form-urlencoded"
    static let applicationFormEncodedUTF8 = "application/x-www-form-urlencoded; charset=UTF-8"
    static let applicationJson = "application/json"
    static let applicationJsonUTF8 = "application/json; charset=UTF-8"
    let type: String
    let attributes: [String: String]

    init(_ type: String) {
        let endOfType = type.firstIndex(of: ";") ?? type.endIndex
        self.type = String(type[..<endOfType])
        var attributes = [String: String]()
        if endOfType < type.endIndex {
            var attributeSection = type[type.index(after: endOfType)...]
            repeat {
                let nextAttributeIndex = attributeSection.firstIndex(of: ";") ?? attributeSection.endIndex
                let attrib = String(attributeSection[..<nextAttributeIndex])
                let equalsIndex = attrib.firstIndex(of: "=") ?? attrib.endIndex
                let name = attrib[..<equalsIndex]
                let value = equalsIndex < attrib.endIndex ? attrib[attrib.index(after: equalsIndex)...] : ""
                attributes[String(name.trimmingCharacters(in: .whitespacesAndNewlines))] = value.trimmingCharacters(in: .whitespacesAndNewlines)
                if nextAttributeIndex < attributeSection.endIndex {
                    attributeSection = attributeSection[attributeSection.index(after: nextAttributeIndex)...]
                } else {
                    break
                }
            } while true
        }
        self.attributes = attributes
    }

    /**
     Gets the part of a string that is just the type. Remember substrings should be short-lived. If you intend to keep it, you'll need a "real" string.

     - Parameter type: the string type
     - Returns: just the type part of a MIME type
     */
    static func getTypeFrom(_ type: String) -> Substring {
        let endOfType = type.firstIndex(of: ";") ?? type.endIndex
        return type[..<endOfType]
    }

    static func isJSON(_ type: String) -> Bool {
        // TODO (maybe): Support other JSON MIME types
        return getTypeFrom(type) == applicationJson
    }
}
