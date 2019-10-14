//
//  FHIRBaseTypes.swift
//  myPHR
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import Foundation

/// Represents a URI. A URI is almost like a URL, except that there is no guarantee that there is a resource behind the URI. (So while you *may* be able to convert a given URI to a URL, you may not.)
public struct URI {
    var value: String

    init(_ value: String) {
        self.value = value
    }
}

public struct Coding {
    public var system: URI?
    public var version: String?
    public var code: String?
    public var display: String?
    public var useSelected: Bool?

    public init(fromJSON json: [String: Any]) {
        // Basically just pull out whatever we can
        if let system = json["system"] as? String {
            self.system = URI(system)
        }
        if let version = json["version"] as? String {
            self.version = version
        }
        if let code = json["code"] as? String {
            self.code = code
        }
        if let display = json["display"] as? String {
            self.display = display
        }
    }

    public func describe() -> String {
        if let display = display {
            return display
        } else if let code = code {
            return code
        } else {
            return "Unknown"
        }
    }
}

public struct CodeableConcept {
    public var coding: [Coding]?
    public var text: String?

    init(fromJSON json: [String: Any]) {
        if let coding = json["coding"] as? [Any] {
            var parsedCodingList = [Coding]()
            for codingInstance in coding {
                if let instanceJSON = codingInstance as? [String: Any] {
                    parsedCodingList.append(Coding(fromJSON: instanceJSON))
                }
            }
            self.coding = parsedCodingList
        }
        if let text = json["text"] as? String {
            self.text = text
        }
    }

    public func describe() -> String {
        if let text = text {
            return text
        }
        // Otherwise, grab whatever the first coding is
        guard let coding = coding,
            let firstCoding = coding.first else {
                return "Invalid CodeableConcept"
        }
        return firstCoding.describe()
    }
}

/// Represents a FHIR DateTime field. FHIR date times are somewhat annoying in that they can be less precise than "real" Dates.
public struct DateTime {
    public var precision: Precision
    public var date: Date
    // TODO: Implement this public var timezone: TimeZone?

    public init?(_ value: String) {
        // For now, cheap out and only parse dates and dateTimes
        let parser = ISO8601DateFormatter()
        parser.formatOptions = [.withFullDate, .withFullTime, .withDashSeparatorInDate]
        if let date = parser.date(from: value) {
            self.date = date
            self.precision = .dateTime
            return
        }
        parser.formatOptions.remove(.withFullTime)
        if let date = parser.date(from: value) {
            self.date = date
            self.precision = .date
            return
        }
        return nil
    }

    public enum Precision {
        /// Only the year part of the date is valid
        case year
        /// Only the year and month part of the date is valid
        case yearMonth
        /// Only the date (year, month, and day) part of the date is valid
        case date
        /// The entire thing is valid
        case dateTime
    }
}

public struct Period {
    var start: Date?
    var end: Date?

    init() { }
    init(start: Date, end: Date) {
        self.start = start
        self.end = end
    }
}

public struct Reference { }

/// Generic FHIR identifier.
public struct Identifier {
    public var use: UseCode?
    public var type: CodeableConcept?
    public var system: URI?
    public var value: String?
    public var period: Period?
    public var assigner: Reference?

    public enum UseCode: String, CaseIterable {
        case usual
        case official
        case temp
        case secondary
    }
}

public struct Annotation {
    // Conceptually authorReference and authorString are a union and cannot both be set at once
    var authorReference: Reference?
    var authorString: String?
    var time: Date?
    var text: String?

    init() { }
    init(fromJSON json: [String: Any]) {
        // TODO: Implement this
    }
}
