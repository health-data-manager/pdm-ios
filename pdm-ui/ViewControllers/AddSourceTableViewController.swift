//
//  AddSourceTableViewController.swift
//  pdm-ui
//
//  Created by Potter, Dan on 5/23/19.
//  Copyright © 2019 MITRE. All rights reserved.
//

import UIKit

/// View for adding a new source.
class AddSourceTableViewController: UITableViewController {
    var availableProviders: [PDMProvider]? {
        didSet {
            let newValue = availableProviders
            DispatchQueue.main.async {
                self.updateTableView(from: oldValue, to: newValue)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if availableProviders == nil {
            loadProviders()
        }
    }

    // MARK: - Provider loading

    /// Loads providers. If called when providers where already loaded, this reloads the providers.
    func loadProviders() {
        if let pdm = patientDataManager {
            print("Loading providers...")
            pdm.loadProviders() { providers, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.presentErrorAlert(error, title: "Error loading providers")
                    } else {
                        self.availableProviders = providers
                    }
                }
            }
        }
    }

    private func updateTableView(from: [PDMProvider]?, to: [PDMProvider]?) {
        tableView.beginUpdates()
        if let from = from {
            // For now, just tell it we're removing everything. In the future we should calculate inserts and deletes.
            var rows = [IndexPath]()
            for index in 0..<from.count {
                rows.append(IndexPath(row: index, section: 0))
            }
            tableView.deleteRows(at: rows, with: .automatic)
        }
        if let to = to {
            var rows = [IndexPath]()
            for index in 0..<to.count {
                rows.append(IndexPath(row: index, section: 0))
            }
            tableView.insertRows(at: rows, with: .fade)
        }
        tableView.endUpdates()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return availableProviders?.count ?? 0
        } else {
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Provider", for: indexPath)
        guard let providers = availableProviders else {
            fatalError("Attempt to get cell before providers loaded")
        }
        let provider = providers[indexPath.row]

        // Configure the cell...
        if let label = cell.textLabel {
            label.text = provider.name
        }

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
        super.prepare(for: segue, sender: sender)
        if segue.identifier == "AddSource" {
            guard let addSourceViewController = segue.destination as? AddSourceViewController,
                let selectedCell = sender as? UITableViewCell,
                let selectedIndex = tableView.indexPath(for: selectedCell) else {
                // Handle?
                return
            }
            addSourceViewController.provider = availableProviders?[selectedIndex.row]
        }
    }
}
