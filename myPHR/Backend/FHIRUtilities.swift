//
//  FHIRUtilities.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import Foundation

/// A list of prefixes of units
class UCUMPrefix {
    /// The display text of the prefix, when formatting for display
    let printedText: String
    let caseSensitive: String
    let caseInsensitive: String
    let power: Int

    static let yotta = UCUMPrefix(printedText: "Y", caseSensitive: "Y", caseInsensitive: "YA", power: 24)
    static let zetta = UCUMPrefix(printedText: "Z", caseSensitive: "Z", caseInsensitive: "ZA", power: 21)
    static let exa = UCUMPrefix(printedText: "E", caseSensitive: "E", caseInsensitive: "EX", power: 18)
    static let peta = UCUMPrefix(printedText: "P", caseSensitive: "P", caseInsensitive: "PT", power: 15)
    static let tera = UCUMPrefix(printedText: "T", caseSensitive: "T", caseInsensitive: "TR", power: 12)
    static let giga = UCUMPrefix(printedText: "G", caseSensitive: "G", caseInsensitive: "GA", power: 9)
    static let mega = UCUMPrefix(printedText: "M", caseSensitive: "M", caseInsensitive: "MA", power: 6)
    static let kilo = UCUMPrefix(printedText: "k", caseSensitive: "k", caseInsensitive: "K", power: 3)
    static let hecto = UCUMPrefix(printedText: "h", caseSensitive: "h", caseInsensitive: "H", power: 2)
    static let deka = UCUMPrefix(printedText: "da", caseSensitive: "da", caseInsensitive: "DA", power: 1)
    static let deci = UCUMPrefix(printedText: "d", caseSensitive: "d", caseInsensitive: "D", power: -1)
    static let centi = UCUMPrefix(printedText: "c", caseSensitive: "c", caseInsensitive: "C", power: -2)
    static let milli = UCUMPrefix(printedText: "m", caseSensitive: "m", caseInsensitive: "M", power: -3)
    static let micro = UCUMPrefix(printedText: "μ", caseSensitive: "u", caseInsensitive: "U", power: -6)
    static let nano = UCUMPrefix(printedText: "n", caseSensitive: "n", caseInsensitive: "N", power: -9)
    static let pico = UCUMPrefix(printedText: "p", caseSensitive: "p", caseInsensitive: "P", power: -12)
    static let femto = UCUMPrefix(printedText: "f", caseSensitive: "f", caseInsensitive: "F", power: -15)
    static let atto = UCUMPrefix(printedText: "a", caseSensitive: "a", caseInsensitive: "A", power: -18)
    static let zepto = UCUMPrefix(printedText: "z", caseSensitive: "z", caseInsensitive: "ZO", power: -21)
    static let yocto = UCUMPrefix(printedText: "y", caseSensitive: "y", caseInsensitive: "YO", power: -24)

    static let allPrefixes = [ yotta, zetta, exa, peta, tera, giga, mega, kilo, hecto, deka, deci, centi, milli, micro, nano, pico, femto, atto, zepto, yocto ]
    static let prefixesByCaseSensitiveName = { () -> [String: UCUMPrefix] in
        var mapping = [String: UCUMPrefix]()
        for prefix in allPrefixes {
            mapping[prefix.caseSensitive] = prefix
        }
        return mapping
    }()
    static let prefixesByCaseInsensitiveName = { () -> [String: UCUMPrefix] in
        var mapping = [String: UCUMPrefix]()
        for prefix in allPrefixes {
            mapping[prefix.caseInsensitive] = prefix
        }
        return mapping
    }()

    init(printedText: String, caseSensitive: String, caseInsensitive: String, power: Int) {
        self.printedText = printedText
        self.caseSensitive = caseSensitive
        self.caseInsensitive = caseInsensitive
        self.power = power
    }

    static func parsePrefix(_ prefix: String, caseSensitive: Bool = false) -> UCUMPrefix? {
        let mappingDB = caseSensitive ? prefixesByCaseSensitiveName : prefixesByCaseInsensitiveName
        // If we're doing a case insenstive match, just force the string to be all uppercase
        return mappingDB[caseSensitive ? prefix : prefix.uppercased()]
    }
}

/// This class represents a unit in a FHIR document. It is intended to convert them into something more human readable from their FHIR form.
///
/// FHIR units are described using the Unified Codes for Units of Measures (UCUM) system.
///
/// At present this is simply a hard-coded list of known units, but in the future, it may be expanded into something more useful.
class FHIRUnit {
    let unit: String

    /// Create a new unit based on a given UCUM string. If the unit cannot be parsed, this fails.
    /// (Note that at present it can't actually fail, but this will change in the future.)
    init?(_ unit: String) {
        self.unit = unit
    }

    /// Converts this unit into a human readable version, if possible. If not possible, the original UCUM definition will be given.
    func humanReadable() -> String {
        return Bundle.main.localizedString(forKey: unit, value: unit, table: "Units")
    }
}
