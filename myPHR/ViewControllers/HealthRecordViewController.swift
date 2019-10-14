//
//  HealthRecordViewController.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import UIKit
import FHIR

// Internal helper class to deal with showing simple fields
class FieldViewController {
    let view: UIStackView
    let fieldLabel: UILabel
    let valueLabel: UILabel

    init(field: String, value: String) {
        fieldLabel = UILabel()
        valueLabel = UILabel()
        fieldLabel.text = field
        valueLabel.text = value
        view = UIStackView(arrangedSubviews: [fieldLabel, valueLabel])
    }
}

/// This is currently mostly a placeholder view controller
class HealthRecordViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var badgeLabel: UILabel!
    @IBOutlet weak var headerView: UIStackView!
    @IBOutlet weak var fieldsView: UIStackView!
    var record: FHIRResource?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let record = record else {
            titleLabel.text = "No record set"
            dateLabel.text = "Internal Error: No record given to view"
            badgeLabel.text = nil
            return
        }
        if let allergyIntolerance = record as? AllergyIntolerance {
            titleLabel.text = allergyIntolerance.substance?.describe() ?? "Unknown"
            // See if there's a diagnosis date
            if let recordedDate = allergyIntolerance.recordedDate {
                print("Recorded date exists: \(recordedDate)")
                print("Date parsed to: \(recordedDate.date.debugDescription)")
                dateLabel.text = "Diagnosed on \(PDMTheme.formatDate(recordedDate.date))"
            } else {
                dateLabel.text = nil
            }
            if let reaction = allergyIntolerance.reaction, let firstReaction = reaction.first, let severity = firstReaction.severity {
                badgeLabel.text = severity.rawValue
            } else {
                badgeLabel.text = nil
            }
        } else {
            titleLabel.text = record.describe()
            dateLabel.text = nil
            badgeLabel.text = nil
        }
    }

    private func addDateField(_ name: String, date: Date) {
        addField(name, value: PDMTheme.formatDate(date))
    }

    private func addField(_ name: String, value: String) {
        let fieldController = FieldViewController(field: name, value: value)
        fieldsView.addArrangedSubview(fieldController.view)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let jsonController = segue.destination as? HealthRecordJSONViewController {
            jsonController.record = record
        }
    }
}
