//
//  ConnectedSourcesTableViewController.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import UIKit

/// Displays the sources connected to by a given user.
class ConnectedSourcesTableViewController: UITableViewController {
    @IBOutlet weak var addSourceButton: UIBarButtonItem!

    /// Data source for the table
    private var connectedProviders = [PDMProvider]()
    private var providerLinks = [PDMProviderProfileLink]()
    /// The new provider links that should be used to populate both providerLinks and connectedProviders once loading has completed.
    private var newProviderLinks: [PDMProviderProfileLink]?
    private var availableProviders = PDMProviderList()
    // Various bits of state that need to exist while loading
    private var didLoadProviders = false
    private var shouldReloadLinkedProviders = false
    private var providerLoadErrors: [Error]?
    private var providerGroup = DispatchGroup()

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
        loadConnectedProviders()
    }

    /// Reloads the connected providers, assuming the providers have been loaded. If the providers have not been loaded yet, this does nothing. (Note that means there's a somewhat obscure edge condition where connected providers have been loaded but the complete provider list hasn't. Calling this during that time period will not cause the connected providers to be reloaded.)
    func reloadConnectedProviders() {
        guard let pdm = patientDataManager, let profile = pdm.activeProfile else { return }
        addSourceButton.isEnabled = false
        pdm.loadProvidersConnectedTo(profile) { providerLinks, error in
            if let error = error {
                self.presentErrorAlert(error, title: "Error loading connected sources")
            } else if let providerLinks = providerLinks {
                DispatchQueue.main.async {
                    self.newProviderLinks = providerLinks
                    self.updateLinkedProviders()
                }
            }
        }
    }

    /// Forces everything to be reloaded. This will completely empty out the existing data and reload from scratch.
    func reloadProviders() {
        didLoadProviders = false
        connectedProviders.removeAll()
        providerLinks.removeAll()
        availableProviders.removeAll()
        tableView.reloadData()
    }

    /// Load connected providers. This should only be called from the main thread: it makes UI changes and that also makes it simpler to implement.
    private func loadConnectedProviders() {
        // Only load everything once
        if didLoadProviders {
            if shouldReloadLinkedProviders {
                // In this case, we just reload the links and then repopulate the list
                reloadConnectedProviders()
                shouldReloadLinkedProviders = false
            }
            return
        }
        guard let pdm = patientDataManager, let profile = pdm.activeProfile else { return }
        // At this point mark ourselves as having loaded the providers so we won't reload them
        // At some point this should be more intelligent to allow reloading providers/linked providers
        // and repopulating the data
        didLoadProviders = true
        tableView.setEmptyMessage("Loading...")
        // Disable the add source button during loading
        addSourceButton.isEnabled = false
        // So we actually need to load two things: the complete list of providers and the list of links
        providerGroup.enter()
        pdm.loadProvidersConnectedTo(profile) { providerLinks, error in
            if let error = error {
                self.handleLoadError(error)
            } else if let providerLinks = providerLinks {
                self.newProviderLinks = providerLinks
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
                self.addSourceButton.isEnabled = !self.availableProviders.isEmpty
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

    /// Internal function to update a list of linked providers entirely.
    private func updateLinkedProviders() {
        guard let newProviderLinks = newProviderLinks else {
            // If there are no new provider links, do nothing: this is NOT the same case as "empty"
            return
        }
        var newConnectedProviders = availableProviders.getProvidersWithin(newProviderLinks)
        newConnectedProviders.sort(by: {a, b in
            return a.name.localizedCompare(b.name) == .orderedAscending
        })
        // TODO (maybe): Figure out what the edits are. But for now:
        connectedProviders = newConnectedProviders
        tableView.reloadData()
        addSourceButton.isEnabled = true
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
                    // Also indicate we should reload linked providers after this view is reshown
                    shouldReloadLinkedProviders = true
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
}
