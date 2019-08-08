//
//  DataUseAgreement.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import Foundation
import UIKit

enum DataUseAgreementError: Error {
    case configError
    case loadingError
    case serverError(Int)
}

/**
 Provides information on the data use agreement. Currently loaded locally, it will likely eventually be loaded remotely.
 */
class DataUseAgreement {
    /// The pages that make up the data use agreement
    let pages: [DataUseAgreementPage]
    /// The base URL
    let baseURL: URL
    /// The URL for the entire agreement
    let agreementURL: URL

    init?(withConfig config: [String: Any], atBaseURL baseURL: URL) {
        self.baseURL = baseURL
        // Valid configurations require the DUA URL
        guard let urlString = config["url"] as? String else {
            return nil
        }
        guard let url = URL(string: urlString, relativeTo: baseURL)?.absoluteURL else {
            return nil
        }
        self.agreementURL = url
        // Valid configurations must have pages
        guard let pagesConfig = config["pages"] as? [Any] else {
            return nil
        }
        var pages = [DataUseAgreementPage]()
        for pageDefinition in pagesConfig {
            if let pageConfig = pageDefinition as? [String: Any] {
                if let page = DataUseAgreementPage(withConfig: pageConfig, atBaseURL: baseURL, pageNumber: pages.count) {
                    pages.append(page)
                } else {
                    print("Warning: skipped page (bad page configuration)")
                }
            }
        }
        self.pages = pages
    }

    // Handles loading the data use agreement metadata from a given URL.
    @discardableResult class func load(from configURL: URL, callback: @escaping (DataUseAgreement?, Error?) -> Void) -> URLSessionTask {
        let baseURL = configURL.deletingLastPathComponent()
        let task = URLSession.shared.dataTask(with: configURL) { (data, response, error) in
            if error != nil {
                callback(nil, error)
                return
            }
            // If this was an HTTP response, check to make sure it was successful
            if let httpResponse = response as? HTTPURLResponse {
                guard (200...299).contains(httpResponse.statusCode) else {
                    callback(nil, DataUseAgreementError.serverError(httpResponse.statusCode))
                    return
                }
            }
            // For now, always assume the MIME type is correct and try and load any data as JSON
            guard let data = data else {
                callback(nil, DataUseAgreementError.loadingError)
                return
            }
            do {
                let result = try DataUseAgreement.load(fromData: data, atBaseURL: baseURL)
                callback(result, nil)
            } catch {
                callback(nil, DataUseAgreementError.configError)
                return
            }
        }
        // And fetch
        task.resume()
        // Return the task so progress can be monitored
        return task
    }

    class func load(fromData data: Data, atBaseURL baseURL: URL) throws -> DataUseAgreement  {
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        guard let config = json as? [String: Any] else {
            throw DataUseAgreementError.configError
        }
        if let result = DataUseAgreement(withConfig: config, atBaseURL: baseURL) {
            return result
        } else {
            throw DataUseAgreementError.configError
        }
    }
}

/// A single page within the data use agreement.
class DataUseAgreementPage {
    var image: URL
    var accessibilityLabel: String?
    var accessibilityHint: String?
    var nextLabel: String?
    var legal: [String]?
    var pageNumber: Int

    init?(withConfig config: [String: Any], atBaseURL baseURL: URL, pageNumber: Int) {
        // Page must have an image
        guard let imagePath = config["image"] as? String else {
            return nil
        }
        guard let imageURL = URL(string: imagePath, relativeTo: baseURL) else {
            return nil
        }
        self.image = imageURL
        if let accessibility = config["accessibility"] as? [String: Any] {
            self.accessibilityLabel = accessibility["label"] as? String
            self.accessibilityHint = accessibility["hint"] as? String
        } else {
            self.accessibilityLabel = config["accessibilityLabel"] as? String
        }
        self.nextLabel = config["nextLabel"] as? String
        // Config can either be a single value or an array
        if let legal = config["legal"] as? String {
            self.legal = [ legal ]
        } else if let legalArray = config["legal"] as? [Any] {
            // If an array, only pull out string values (all other values are ignored)
            var legal = [String]()
            for value in legalArray {
                if let string = value as? String {
                    legal.append(string)
                }
            }
            // If we didn't find anything, leave this set to be nil
            if !legal.isEmpty {
                self.legal = legal
            }
        }
        self.pageNumber = pageNumber
    }
}
