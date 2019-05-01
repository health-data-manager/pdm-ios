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
    case formInvalid([String: [String]])
}

// The PatientDataManager object. This is intended to be a singleton that represents the connection to the PatientDataManager web server. Conceptually multiple instances could exist that provide connections to different PDMs.
class PatientDataManager {
    let rootURL: URL
    let clientId: String
    let clientSecret: String
    // Optional HealthKit support. If the current device does not support HealthKit, this will be nil.
    let healthKit: PDMHealthKit?
    var bearerToken: String?
    var userBearerToken: String?
    var user: User?

    // Generated URLs.
    var oauthTokenURL: URL {
        return rootURL.appendingPathComponent("oauth/token")
    }

    var usersURL: URL {
        return rootURL.appendingPathComponent("users")
    }

    init?(withConfig config: [String: Any]) {
        guard let urlString = config["RootURL"] as? String,
            let rootURL = URL(string: urlString),
            let clientId = config["ClientID"] as? String,
            let clientSecret = config["ClientSecret"] as? String else {
                return nil
        }
        self.rootURL = rootURL
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.healthKit = PDMHealthKit()
    }

    func signInAsUser(email: String, password: String, completionHandler: @escaping (Error?) -> Void) {
        // This uses the same token login the client login would use
        do {
            try HTTP.postTo(oauthTokenURL, withJSON: [ "email": email, "password": password, "grant_type": "password" ], completionHandler: { data, response, error in
                if let error = error {
                    if let data = data, let httpFormError = error as? HTTPFormError {
                        switch httpFormError {
                        case .serverError(let statusCode):
                            if statusCode == 401 {
                                // This could be a login failure
                                do {
                                    let jsonResponse = try JSONSerialization.jsonObject(with: data, options: [])
                                    guard let jsonResponseDictionary = jsonResponse as? [String: Any] else {
                                        completionHandler(PatientDataManagerError.couldNotUnderstandResponse)
                                        return
                                    }
                                    if let jsonError = jsonResponseDictionary["error"] as? String, jsonError == "invalid_grant" {
                                        completionHandler(PatientDataManagerError.loginFailed)
                                    }
                                } catch {
                                    // Do nothing and fall through
                                }
                            }
                            fallthrough
                        default:
                            // Otherwise we do nothing
                            break
                        }
                    }
                    completionHandler(error)
                    return
                }
                // Otherwise, for now, assume OK
                completionHandler(nil)
            })
        } catch {
            // This means that the JSON we generated was bad, which should not be possible
            completionHandler(PatientDataManagerError.internalError)
        }
    }

    func createNewUserAccount(firstName: String, lastName: String, email: String, password: String, passwordConfirmation: String?, completionHandler: @escaping (Error?, User?) -> Void) throws {
        try HTTP.postTo(usersURL, withJSON: [
                "user": [
                    "email": email,
                    "first_name": firstName,
                    "last_name": lastName,
                    "password": password,
                    "password_confirmation": passwordConfirmation ?? password
                ]
            ]) { data, response, error in
            if let error = error {
                if let data = data, let response = response {
                    if response.statusCode == 422 {
                        do {
                            if let errors = try PatientDataManager.decodeErrors(data) {
                                completionHandler(PatientDataManagerError.formInvalid(errors), nil)
                                return
                            }
                        } catch {
                            completionHandler(error, nil)
                            return
                        }
                    }
                }
                completionHandler(error, nil)
                return
            }
            if let data = data, let response = response {
                if response.statusCode == 201 {
                    // This is a success
                    do {
                        guard let user = try User(fromData: data) else {
                            completionHandler(PatientDataManagerError.couldNotUnderstandResponse, nil)
                            return
                        }
                        completionHandler(nil, user)
                        return
                    } catch {
                        completionHandler(error, nil)
                        return
                    }
                }
                completionHandler(PatientDataManagerError.serverReturnedError(response.statusCode), nil)
                return
            }
            completionHandler(PatientDataManagerError.internalError, nil)
        }
    }

    // Logs in with the client secret
    func clientLogin(completionHandler: @escaping (Error?) -> Void) {
        guard let request = URLRequest.httpPostRequestTo(oauthTokenURL, withFormValues: [
                "client_id": clientId,
                "client_secret": clientSecret,
                "grant_type": "client_credentials"
            ]) else {
                completionHandler(PatientDataManagerError.internalError)
                return
        }
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

    // Assuming the user is logged in, this gets the user information for their current account. If the user has already been loaded, this immediately completes. Otherwise, it posts an HTTP request to get the user information.
    func getUserInformation(completionHandler: @escaping (Error?, User?) -> Void) {
        if let user = user {
            completionHandler(nil, user)
            return
        }
    }

    func uploadHealthRecord(_ record: HKClinicalRecord, completionCallback: @escaping (Error?) -> Void) {
        guard let url = URL(string: "api/v1/$process-message", relativeTo: rootURL) else {
            fatalError("could not create process-message URL")
        }
        // The data should be a single resource which needs to be wrapped into a bundle
        let bundle = MessageBundle()
        if let pID = user?.id {
            bundle.addPatientId(String(pID))
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

    // Attempts to decode a JSON object that describes form errors
    static func decodeErrors(_ data: Data) throws -> [String: [String]]? {
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        guard let jsonDict = json as? [String: Any],
            let errors = jsonDict["errors"],
            let errorDict = errors as? [String: Any] else {
                return nil
        }
        var result = [String: [String]]()
        for (field, errorsAny) in errorDict {
            if let errorsList = errorsAny as? [String] {
                result[field] = errorsList
            } else {
                result[field] = [ "Server returned \(String(describing: errorsAny))" ]
            }
        }
        return result
    }
}
