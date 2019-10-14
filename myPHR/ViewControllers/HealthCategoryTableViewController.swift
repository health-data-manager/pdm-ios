//
//  HealthCategoryTableViewController.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import UIKit
import FHIR

/// A table view cell showing a health record's details.
class HealthCategoryTableViewCell : UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var severityLabel: UILabel!

    var resource: FHIRResource? {
        didSet {
            updateLabels()
        }
    }

    func updateLabels() {
        if let resource = resource {
            // First do the defaults
            nameLabel.text = resource.describe()
            descriptionLabel.isHidden = true
            dateLabel.isHidden = true
            severityLabel.isHidden = true
            // Check to see if we can do anything with this resource
            if let allergyIntolerance = resource as? AllergyIntolerance {
                // For now, just use the first reaction
                if let reactions = allergyIntolerance.reaction, let reaction = reactions.first {
                    if let severity = reaction.severity {
                        severityLabel.isHidden = false
                        severityLabel.text = severity.rawValue
                    }
                    if let manifestations = reaction.manifestation, let manifestation = manifestations.first {
                        descriptionLabel.text = manifestation.describe()
                        descriptionLabel.isHidden = false
                    }
                }
                if let recordedDate = allergyIntolerance.recordedDate {
                    dateLabel.text = PDMTheme.formatDate(recordedDate.date)
                    dateLabel.isHidden = false
                }
            }
        } else {
            nameLabel.text = "Nil"
            descriptionLabel.text = "(An internal error is preventing this instance from being displayed)"
            dateLabel.isHidden = true
            severityLabel.isHidden = true
        }
    }
}

/// For showing health category information. The same view controller is used for each category, although the exact reuse cell can be changed based on category.
class HealthCategoryTableViewController: UITableViewController {
    var category: PHRCategory?
    var records: [FHIRResource]?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Set the proper title now
        if let category = category {
            title = category.localizedName
        } else {
            title = "Unknown"
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // Always just 1 section
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section != 0 {
            return 0
        }
        return records?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BasicItem", for: indexPath)

        guard let resourceCell = cell as? HealthCategoryTableViewCell else {
            // This prevents us from showing data
            return cell
        }
        guard let records = records, indexPath.row >= 0, indexPath.row < records.count else {
            // This is a degenerate case, cells should never be displayed if records is nil
            resourceCell.resource = nil
            return cell
        }

        resourceCell.resource = records[indexPath.row]

        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Details" {
            guard let recordViewController = segue.destination as? HealthRecordViewController,
                let indexPath = tableView.indexPathForSelectedRow,
                let records = records,
                indexPath.row >= 0, indexPath.row < records.count else {
                return
            }
            recordViewController.record = records[indexPath.row]
        }
    }

}
