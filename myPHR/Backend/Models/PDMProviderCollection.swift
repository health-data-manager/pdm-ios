//
//  PDMProviderCollection.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import Foundation

/// A collection of providers within a Patient Data Manager.
///
/// This class essentially acts as a data model for the complete provider list.
class PDMProviderCollection {
    // Instance variables need to be private because external users shouldn't touch them directly
    private var providersById = [Int64: PDMProvider]()

    /// A property indicating if there are no providers within this list.
    var isEmpty: Bool {
        return providersById.isEmpty
    }

    /// Creates an empty provider list
    init() {
        // Does nothing
    }

    /// Creates a provider list populated with the given providers.
    ///
    /// This is currently identical to doing
    ///
    ///     let providerList = PDMProviderList()
    ///     providerList.merge(providers)
    ///
    /// - Parameter providers: the initial providers
    init(withProviders providers: [PDMProvider]) {
        merge(contentsOf: providers)
    }

    /// Adds a given provider. If a provider by that ID already exits, this replaces that provider.
    ///
    /// - Parameter provider: the provider to add
    func add(_ provider: PDMProvider) {
        providersById[provider.id] = provider
    }

    /// Replaces all providers currently in the list with the given list of providers.
    ///
    /// - Parameter sequence: the new providers to use
    func replaceWith(contentsOf sequence: [PDMProvider]) {
        removeAll()
        merge(contentsOf: sequence)
    }

    /// Merges the list of providers to this list. The most recently added provider by a given ID will be the provider returned for that ID. If multiple providers are given with the same ID, the last one with that ID will be the one that remains in the collection.
    ///
    /// - Parameter sequence: the providers to add
    func merge(contentsOf sequence: [PDMProvider]) {
        for provider in sequence {
            providersById[provider.id] = provider
        }
    }

    /// Finds a provider by its ID. If there is no associated provider for the given ID, this returns `nil`.
    ///
    /// - Parameter index: the ID of the provider
    subscript(index: Int64) -> PDMProvider? {
        return providersById[index]
    }

    /// Finds a provider by its ID.
    ///
    /// - Parameter id: the provider ID
    /// - Returns: the provider or `nil` if it is unknown
    func findProviderById(_ id: Int64) -> PDMProvider? {
        return providersById[id]
    }

    /// Converts the given list of linked providers into a list of providers. If a provider could not be found, it will simply not be included. This means that if the returned list is shorter than the given list, not all providers could be located. If the same provider is listed multiple times (and exists), it will be included multiple times.
    ///
    /// - Parameter linkedProviders: a list of linked providers to include
    /// - Returns: the provider metadata for those providers
    /// - Tag: getProvidersWithin
    func getProvidersWithin(_ linkedProviders: [PDMProviderProfileLink]) -> [PDMProvider] {
        var result = [PDMProvider]()
        for link in linkedProviders {
            if let provider = providersById[link.providerId] {
                result.append(provider)
            }
        }
        return result
    }

    /// The exact opposite of [getProvidersWithin](x-source-tag://getProvidersWithin): returns the providers that are NOT in the list. This is used to populate a list of providers that can be added.
    ///
    /// - Parameter linkedProviders: a list of linked providers to exclude
    /// - Returns: a list that does **not** contain any of the linked providers
    func getProvidersWithout(_ linkedProviders: [PDMProviderProfileLink]) -> [PDMProvider] {
        var result = [PDMProvider]()
        var linkIdSet = Set<Int64>()
        for link in linkedProviders {
            linkIdSet.insert(link.providerId)
        }
        for (id, provider) in providersById {
            if !linkIdSet.contains(id) {
                result.append(provider)
            }
        }
        return result
    }

    /// Removes all providers from this list.
    func removeAll() {
        providersById.removeAll()
    }
}
