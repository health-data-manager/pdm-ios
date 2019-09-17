//
//  PDMProfileSourceDataController.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import Foundation

/// Delegate for receiving information from the data source. Note that calls may not happen on the main thread.
protocol PDMProfileSourceDataDelegate {
    /// Indicates an error occurred while loading profile data.
    ///
    /// - Parameters:
    ///   - controller: the controller sending the error
    ///   - error: the error that happened
    func profileSource(_ controller: PDMProfileSourceDataController, didEncounterError error: Error)

    /// Called when the collection of all providers has changed.
    ///
    /// - Parameters:
    ///   - controller: the controller sending the notification
    ///   - collection: the newly updated collection of provider sources
    func profileSource(_ controller: PDMProfileSourceDataController, didUpdateProviderCollection collection: PDMProviderCollection)

    /// Called when the collection of linked providers has changed.
    ///
    /// - Parameters:
    ///   - controller: the controller sending the notification
    ///   - list: the new profile links
    func profileSource(_ controller: PDMProfileSourceDataController, didUpdateLinkedProviderList list: [PDMProviderProfileLink])
}

/// This class manages loading data from the PDM and storing it. It informs the views when new data is ready.
class PDMProfileSourceDataController {
    let patientDataManager: PatientDataManager
    // TODO: At some point this may become mutable as changing it is mostly OK, it just would invalidate the linked providers
    let profile: PDMProfile
    let delegate: PDMProfileSourceDataDelegate
    let allProviders = PDMProviderCollection()
    var isProvidersLoaded: Bool {
        return self.didLoadAllProviders
    }
    private var didLoadAllProviders = false
    private var linkedProviders: [PDMProviderProfileLink]?
    private let queue: DispatchQueue
    /// The task loading all providers
    private var allProvidersLoadTask: URLSessionTask?
    /// The task loading all linked providers
    private var linkedProvidersLoadTask: URLSessionTask?

    init(forPatientDataManager pdm: PatientDataManager, andProfile profile: PDMProfile, withDelegate delegate: PDMProfileSourceDataDelegate) {
        self.patientDataManager = pdm
        self.profile = profile
        self.delegate = delegate
        self.queue = DispatchQueue(label: "pdm.ProfileSourceQueue")
    }

    convenience init?(forPatientDataManager pdm: PatientDataManager, withDelegate delegate: PDMProfileSourceDataDelegate) {
        guard let profile = pdm.activeProfile else { return nil }
        self.init(forPatientDataManager: pdm, andProfile: profile, withDelegate: delegate)
    }

    /// Load all data. Returns immediately: delegate callbacks will be invoked when data is ready.
    func loadAll() {
        updateAllProviders()
        updateConnectedProviders()
    }

    /// Instruct all providers to load.
    func updateAllProviders() {
        queue.async {
            if self.allProvidersLoadTask == nil {
                // Fire off a new task to load all providers
                self.allProvidersLoadTask = self.patientDataManager.loadAllProviders() { providers, error in
                    self.queue.async {
                        // Always nil out this task
                        self.allProvidersLoadTask = nil
                        if let error = error {
                            self.delegate.profileSource(self, didEncounterError: error)
                        } else if let providers = providers {
                            // Need to know if we've loaded and empty is valid - which it conceptually could be
                            self.didLoadAllProviders = true
                            self.allProviders.replaceWith(contentsOf: providers)
                            self.delegate.profileSource(self, didUpdateProviderCollection: self.allProviders)
                        }
                    }
                }
            }
        }
    }

    /// Instruct all providers to load.
    func updateConnectedProviders() {
        queue.async {
            if self.linkedProvidersLoadTask == nil {
                self.linkedProvidersLoadTask = self.patientDataManager.loadProvidersConnectedTo(self.profile) { providerLinks, error in
                    self.queue.async {
                        // Always nil out this task
                        self.linkedProvidersLoadTask = nil
                        if let error = error {
                            self.delegate.profileSource(self, didEncounterError: error)
                        } else if let providerLinks = providerLinks {
                            self.linkedProviders = providerLinks
                            self.delegate.profileSource(self, didUpdateLinkedProviderList: providerLinks)
                        }
                    }
                }
            }
        }
    }
}
