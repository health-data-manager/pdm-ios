//
//  ConnectedSourcesTableViewController.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import UIKit

/// Displays the sources connected to by a given user.
class ConnectedSourcesTableViewController: UITableViewController, PDMProfileSourceDataDelegate {
    @IBOutlet weak var addSourceButton: UIBarButtonItem!

    /// Data source for the table. Created on viewDidAppear if doesn't already exist
    private var dataSource: PDMProfileSourceDataController?
    private var allProviders: PDMProviderCollection?
    private var providerLinks: [PDMProviderProfileLink]?
    private var connectedProviders = [PDMProvider]()
    private var shouldReloadLinkedProviders = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem

        // The add source button should always start disabled
        addSourceButton.isEnabled = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let dataSource = dataSource {
            // If the data source already exists, assume we have the necessary providers.
            if shouldReloadLinkedProviders {
                shouldReloadLinkedProviders = false
                dataSource.updateConnectedProviders()
                // Always disable the add source button while loading
                addSourceButton.isEnabled = false
            }
        } else {
            guard let pdm = patientDataManager, let profile = pdm.activeProfile else {
                // Handle this in some fashion?
                return
            }
            let dataSource = PDMProfileSourceDataController(forPatientDataManager: pdm, andProfile: profile, withDelegate: self)
            self.dataSource = dataSource
            dataSource.loadAll()
            // Always disable the add source button while loading
            addSourceButton.isEnabled = false
        }
    }

    private func appendConnectedProviders(_ providers: [PDMProvider]) {
        // If nothing is being added, don't do anything
        if providers.isEmpty {
            return
        }
        let startIndex = connectedProviders.count
        connectedProviders.append(contentsOf: providers)
        let lastIndex = connectedProviders.count
        var changedRows = [IndexPath]()
        for index in (startIndex..<lastIndex) {
            changedRows.append(IndexPath(row: index, section: 0))
        }
        tableView.beginUpdates()
        if startIndex == 0 {
            // also inserting a complete section
            tableView.insertSections(IndexSet(arrayLiteral: 0), with: .automatic)
        }
        tableView.insertRows(at: changedRows, with: .automatic)
        tableView.endUpdates()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if connectedProviders.isEmpty {
            let message = NSMutableAttributedString(string: "No connected providers", attributes: [.font: UIFont.boldSystemFont(ofSize: 21.0)])
            message.append(NSAttributedString(string: "\n\nYou can add a provider using the button above.", attributes: [.font: UIFont.systemFont(ofSize: 17.0)]))
            tableView.setEmptyMessage(message)
            return 0
        } else {
            tableView.clearEmptyMessage()
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? connectedProviders.count : 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Source", for: indexPath)

        let provider = connectedProviders[indexPath.row]
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
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "AddSource" {
            if let navigationController = segue.destination as? UINavigationController,
                let addSourceViewController = navigationController.visibleViewController as? AddSourceTableViewController,
                let allProviders = allProviders,
                let providerLinks = providerLinks {
                    addSourceViewController.availableProviders = allProviders.getProvidersWithout(providerLinks)
                    // Also indicate we should reload linked providers after this view is reshown
                    shouldReloadLinkedProviders = true
            }
        } else {
            print("Unknown segue to \(segue.identifier ?? "nil")")
        }
    }

    // MARK: - Data Controller callbacks
    func profileSource(_ controller: PDMProfileSourceDataController, didEncounterError error: Error) {
        presentErrorAlert(error, title: "Error loading sources")
    }

    func profileSource(_ controller: PDMProfileSourceDataController, didUpdateProviderCollection collection: PDMProviderCollection) {
        DispatchQueue.main.async {
            self.allProviders = collection
            self.updateLinkedProviders()
        }
    }

    func profileSource(_ controller: PDMProfileSourceDataController, didUpdateLinkedProviderList list: [PDMProviderProfileLink]) {
        DispatchQueue.main.async {
            self.providerLinks = list
            self.updateLinkedProviders()
        }
    }

    func updateLinkedProviders() {
        if let allProviders = allProviders, let providerLinks = providerLinks {
            // Reset data
            connectedProviders = allProviders.getProvidersWithin(providerLinks)
            tableView.reloadData()
            // At this point we can enable adding sources
            addSourceButton.isEnabled = true
        }
    }
}
