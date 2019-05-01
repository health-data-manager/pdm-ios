//
//  HealthRecordTableViewController.swift
//  Health Data Manager
//
//  Created by Potter, Dan on 3/13/19.
//  Copyright © 2019 MITRE. All rights reserved.
//

import UIKit
import HealthKit

class HealthRecordTableViewController: UITableViewController {
    var healthRecords = [HKClinicalRecord]()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem

        // The assumption here is that we have the health store ready
        // Unfortunately each available type must be requested individually
        guard let pdm = patientDataManager, let healthKit = pdm.healthKit else {
            return
        }
        for recordType in healthKit.availableTypes {
            let query = HKSampleQuery(sampleType: recordType, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
                // Results will come in off the main thread
                guard let actualSamples = samples else {
                    // TODO: Report the error somewhere
                    print("*** An error occurred: \(error?.localizedDescription ?? "nil") ***")
                    return
                }

                let records = actualSamples as? [HKClinicalRecord]
                if records != nil {
                    DispatchQueue.main.async {
                        self.addRecords(records!)
                    }
                }
            }
            healthKit.healthStore.execute(query)
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // TODO (maybe): Split by type?
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return healthRecords.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Record", for: indexPath)

        let record = healthRecords[indexPath.row]
        cell.textLabel!.text = record.displayName

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
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
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
        super.prepare(for: segue, sender: sender)

        switch (segue.identifier ?? "") {
        case "Show":
            guard let healthRecordView = segue.destination as? HealthRecordViewController else {
                fatalError("Segueing to unknown destination \(segue.destination)")
            }
            guard let selectedCell = sender as? UITableViewCell else {
                fatalError("Unexpected sender: \(String(describing: sender))")
            }
            guard let indexPath = tableView.indexPath(for: selectedCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            healthRecordView.healthRecord = healthRecords[indexPath.row]
        default:
            fatalError("Unexpected segue: \(String(describing: segue.identifier))")
        }
    }

    // Handles adding multiple records at once.
    func addRecords(_ records: [HKClinicalRecord]) {
        if records.count == 0 {
            // Do nothing
            return
        }
        let firstNewIndex = healthRecords.count
        var rows = [IndexPath]()
        rows.reserveCapacity(healthRecords.count)
        tableView.beginUpdates()
        healthRecords.append(contentsOf: records)
        for index in firstNewIndex..<(firstNewIndex + records.count) {
            rows.append(IndexPath(row: index, section: 0))
        }
        tableView.insertRows(at: rows, with: .fade)
        tableView.endUpdates()
    }

    func addRecord(_ record: HKClinicalRecord) {
        tableView.beginUpdates()
        healthRecords.append(record)
        tableView.insertRows(at: [IndexPath(row: healthRecords.count - 1, section: 0)], with: .fade)
        tableView.endUpdates()
    }
}
