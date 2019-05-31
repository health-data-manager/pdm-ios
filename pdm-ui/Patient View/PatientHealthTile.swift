//
//  PatientHealthTile.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import Foundation

/// A tile showing data within the patient health record view.
class PatientHealthTile {
    var title: String
    var measurement: String
    var type: PDMRecordType
    var units: String?
    var delta: String?
    var source: String?
    var link: String?

    init(title: String, measurement: String, type: PDMRecordType, units: String?=nil, delta: String?=nil, source: String?=nil, link: String?=nil) {
        self.title = title
        self.measurement = measurement
        self.type = type
        self.units = units
        self.delta = delta
        self.source = source
        self.link = link
    }

    func jsonValue() -> [String: Any] {
        var result = [
            "title": title,
            "measurement": measurement,
            "type": type.cssName
        ]
        if let units = units {
            result["units"] = units
        }
        if let delta = delta {
            result["delta"] = delta
        }
        if let source = source {
            result["source"] = source
        }
        if let link = link {
            result["link"] = link
        }
        return result
    }
}
