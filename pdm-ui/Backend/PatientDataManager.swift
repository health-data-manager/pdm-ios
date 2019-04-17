//
//  PatientDataManager.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import Foundation
import HealthKit

enum PatientDataManagerError: Error {
    case internalError
    case serverReturnedError(Int)
    case couldNotUnderstandResponse
    case loginFailed
}

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
        guard let urlString = config["RootURL"] as? String,
            let rootURL = URL(string: urlString),
            let clientId = config["ClientID"] as? String,
            let clientSecret = config["ClientSecret"] as? String,
            let patientId = config["PatientID"] as? String else {
                return nil
        }
        self.rootURL = rootURL
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.patientId = patientId
    }

    func user(_ user: String, signInWithPassword password: String, completionHandler: @escaping (Error?) -> Void) {
        // This is currently unimplemented and therefore never completes.
    }

    // Logs in with the client secret
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
                completionHandler(error)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                // Huh?
                completionHandler(PatientDataManagerError.internalError)
                return
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                completionHandler(PatientDataManagerError.serverReturnedError(httpResponse.statusCode))
                return
            }
            // Decode the JSON response
            if let mimeType = httpResponse.mimeType, mimeType == "application/json", let data = data {
                do {
                    let jsonResponse = try JSONSerialization.jsonObject(with: data, options: [])
                    guard let jsonResponseDictionary = jsonResponse as? [String: Any],
                        jsonResponseDictionary["token_type"] as? String == "bearer" else {
                            completionHandler(PatientDataManagerError.couldNotUnderstandResponse)
                            return
                    }
                    self.bearerToken = jsonResponseDictionary["access_token"] as? String
                    if self.bearerToken != nil {
                        completionHandler(nil)
                        return
                    } else {
                        completionHandler(PatientDataManagerError.couldNotUnderstandResponse)
                        return
                    }
                } catch {
                    completionHandler(error)
                    return
                }
            }
        }
        task.resume()
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
                    completionCallback(error)
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse else {
                    completionCallback(PatientDataManagerError.internalError)
                    return
                }
                guard (200...299).contains(httpResponse.statusCode) else {
                    completionCallback(PatientDataManagerError.serverReturnedError(httpResponse.statusCode))
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
