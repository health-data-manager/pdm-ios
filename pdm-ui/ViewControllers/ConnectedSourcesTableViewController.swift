//
//  ConnectedSourcesTableViewController.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import UIKit

/// Displays the sources connected to by a given user.
class ConnectedSourcesTableViewController: UITableViewController {
    /// Data source for the table
    var connectedProviders = [PDMProvider]()
    var providerLinks = [PDMProviderProfileLink]()
    var availableProviders = PDMProviderList()
    // Various bits of state that need to exist while loading
    private var didLoadProviders = false
    private var providerLoadErrors: [Error]?
    private var providerGroup = DispatchGroup()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadConnectedProviders()
    }

    private func loadConnectedProviders() {
        // Only load once
        if didLoadProviders {
            return
        }
        guard let pdm = patientDataManager, let profile = pdm.activeProfile else { return }
        // At this point mark ourselves as having loaded the providers so we won't reload them
        // At some point this should be more intelligent to allow reloading providers/linked providers
        // and repopulating the data
        didLoadProviders = true
        tableView.setEmptyMessage("Loading...")
        // So we actually need to load two things: the complete list of providers and the list of links
        providerGroup.enter()
        pdm.loadProvidersConnectedTo(profile) { providerLinks, error in
            if let error = error {
                self.handleLoadError(error)
            } else if let providerLinks = providerLinks {
                self.providerLinks.append(contentsOf: providerLinks)
            }
            self.providerGroup.leave()
        }
        providerGroup.enter()
        pdm.loadAllProviders() { providers, error in
            if let error = error {
                self.handleLoadError(error)
            } else if let providers = providers {
                self.availableProviders.append(contentsOf: providers)
            }
            self.providerGroup.leave()
        }
        providerGroup.notify(queue: DispatchQueue.main) {
            // This gets called on the main queue when everything is loaded
            if let errors = self.providerLoadErrors {
                // If there are errors, show them
                if errors.count == 1 {
                    self.presentErrorAlert(errors[0], title: "Error Loading Providers")
                } else {
                    var message = "Multiple errors prevented providers from being loaded:"
                    for error in errors {
                        message.append("\n \u{2022} ")
                        message.append(error.localizedDescription)
                    }
                    self.presentAlert(message, title: "Error Loading Providers")
                }
            } else {
                // Otherwise, we're good to go
                self.appendConnectedProviders(self.availableProviders.getProvidersWithin(self.providerLinks))
                if self.connectedProviders.isEmpty {
                    // If we're still empty, update the message
                    _ = self.numberOfSections(in: self.tableView)
                } else {
                    self.tableView.clearEmptyMessage()
                }
            }
        }
    }

    private func handleLoadError(_ error: Error) {
        // These need to be dealt with on a single thread
        DispatchQueue.main.async {
            if self.providerLoadErrors == nil {
                self.providerLoadErrors = [error]
            } else {
                self.providerLoadErrors!.append(error)
            }
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
            if let navigationController = segue.destination as? UINavigationController {
                if let addSourceViewController = navigationController.visibleViewController as? AddSourceTableViewController {
                addSourceViewController.availableProviders = availableProviders.getProvidersWithout(providerLinks)
                } else {
                    fatalError("Unable to get add source view controller")
                }
            } else {
                fatalError("Unexpected segue to unknown view controller \(segue.destination)")
            }
        } else {
            print("Unknown segue to \(segue.identifier ?? "nil")")
        }
    }

    func unwindFromAddSource(_ segue: UIStoryboardSegue) {
    }
}
