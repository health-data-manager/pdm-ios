//
//  PatientDataManager.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import Foundation
import HealthKit

// The "actual" PatientDataManager. This is intended to be a singleton that represents the connection to the PatientDataManager web server.
class PatientDataManager {
    // It's probably possible to create this list via reflection but conceptually we should limit it to documents we can handle anyway
    static let supportedTypes = [
        HKClinicalTypeIdentifier.allergyRecord,
        HKClinicalTypeIdentifier.conditionRecord,
        HKClinicalTypeIdentifier.immunizationRecord,
        HKClinicalTypeIdentifier.labResultRecord,
        HKClinicalTypeIdentifier.medicationRecord,
        HKClinicalTypeIdentifier.procedureRecord,
        HKClinicalTypeIdentifier.vitalSignRecord
    ]

    var rootURL: URL
    var clientId: String
    var clientSecret: String
    var bearerToken: String?
    var patientId: String?

    init?(withConfig config: [String: Any]) {
        guard let urlString = config["RootURL"] as? String else {
            return nil
        }
        guard let rootURL = URL(string: urlString) else {
            return nil
        }
        guard let clientId = config["ClientID"] as? String else {
            return nil
        }
        guard let clientSecret = config["ClientSecret"] as? String else {
            return nil
        }
        guard let patientId = config["PatientID"] as? String else {
            return nil
        }
        self.rootURL = rootURL
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.patientId = patientId
    }

    func clientLogin(completionHandler: @escaping (Error?) -> Void) {
        guard let url = URL(string: "oauth/token", relativeTo: rootURL) else {
            fatalError("could not create oauth URL")
        }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60.0)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = "client_id=\(clientId)&client_secret=\(clientSecret)&grant_type=client_credentials".data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                self.handleClientError(error)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode) else {
                    self.handleServerError(response)
                    return
            }
            // Decode the JSON response
            if let mimeType = httpResponse.mimeType, mimeType == "application/json", let data = data {
                do {
                    let jsonResponse = try JSONSerialization.jsonObject(with: data, options: [])
                    if let jsonResponseDictionary = jsonResponse as? [String: Any] {
                        if jsonResponseDictionary["token_type"] as? String == "bearer" {
                            self.bearerToken = jsonResponseDictionary["access_token"] as? String
                            if self.bearerToken != nil {
                                completionHandler(nil)
                            }
                            print("Successfully logged in: \(String(describing: self.bearerToken))")
                        }
                    }
                } catch {
                    print("Could not log in: \(error)")
                }
            }
        }
        task.resume()
    }

    func handleClientError(_ error: Error?) {
        print("Internal client error")
    }

    func handleServerError(_ response: URLResponse?) {
        print("Error response from server")
    }

    func uploadHealthRecord(_ record: HKClinicalRecord, completionCallback: @escaping (Error?) -> Void) {
        guard let url = URL(string: "api/v1/$process-message", relativeTo: rootURL) else {
            fatalError("could not create process-message URL")
        }
        // The data should be a single resource which needs to be wrapped into a bundle
        let bundle = MessageBundle()
        if let pID = patientId {
            bundle.addPatientId(pID)
        }
        do {
            try bundle.addRecordAsEntry(record)
            var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60.0)
            request.httpMethod = "POST"
            // TODO: Really, it should be an error to even attempt this without a bearer token
            if let token = bearerToken {
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.httpBody = try bundle.createJsonData()
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    self.handleClientError(error)
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse,
                    (200...299).contains(httpResponse.statusCode) else {
                        self.handleServerError(response)
                        return
                }
                completionCallback(nil)
            }
            task.resume()
        } catch {
            // Q: Is this really an error?
            completionCallback(error)
            return
        }
    }
}
