//
//  HealthRecord.swift
//  myPHR
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import Foundation

/// Provides a single unified interface for pulling information from a health record. This is currently primarily used to expose data to the general category view.
///
/// Note that the way protocols work, you can extend an existing class to add these properties (assuming there are no overlaps).
protocol HealthRecord {
    /// A title to use for displaying the record
    var title: String { get }
    /// An optional description describing the record
    var description: String? { get }
    /// An optional time when the record was recorded at - if given, this is also used to sort records into "most recent first"
    var recordedAt: Date? { get }
    /// An optional description of the date in a human readable form. If given, this is displayed below the record. It need not be the recorded date.
    var dateDescription: String? { get }
    /// A short tag to display on the list
    var tag: String? { get }
    /// The tag type - if there is no tag (tag is nil) this value is technically meaningless but generic should be returned
    var tagType: TagType { get }
}

struct HealthRecordField {
    let name: String
    let value: String

    init(_ name: String, value: String) {
        self.name = name
        self.value = value
    }
}

enum TagType {
    /// Tag is generic (should be the default)
    case generic
    /// Tag represents a good thing
    case positive
    /// Tag is negative
    case negative
}
