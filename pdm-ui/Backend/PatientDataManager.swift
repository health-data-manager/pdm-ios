//
//  PatientDataManager.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import Foundation
import HealthKit

/// Various errors that can occur within the Patient Data Manager.
enum PatientDataManagerError: Error {
    /// Some form of internal error prevented the request from being completed
    case internalError

    /// The response from the server could not be understood
    case couldNotUnderstandResponse

    /// The login attempt failed
    case loginFailed

    /// The user is not logged in so the given request does not make sense
    case notLoggedIn

    /// A form contained validation errors
    case formInvalid([String: [String]])

    /// A result was expected from the server but nothing was returned
    case noResultFromServer
}

/**
 The PatientDataManager object. This is intended to be a singleton that represents the connection to the PatientDataManager web server. Conceptually multiple instances could exist that provide connections to different PDMs.
 */
class PatientDataManager {
    let rootURL: URL
    let clientId: String
    let clientSecret: String
    /**
     Optional HealthKit support. If the current device does not support HealthKit, this will be `nil`.
     */
    let healthKit: PDMHealthKit?
    var clientBearerToken: String?
    var userBearerToken: String?
    let userClient = RESTClient()
    var user: PDMUser?
    /**
     The currently active profile. While there can be multiple users associated with an account, health information is only shown from a single active profile.

     Note that this can be nil if it hasn't been loaded yet. Use getActiveProfile to guarantee it's loaded.
     */
    var activeProfile: PDMProfile?

    // Generated URLs.

    /**
     The OAuth token URL (relative to the root URL)
     */
    var oauthTokenURL: URL {
        return rootURL.appendingPathComponent("oauth/token")
    }

    var usersURL: URL {
        return rootURL.appendingPathComponent("users")
    }

    var editUserURL: URL {
        return rootURL.appendingPathComponent("users/edit")
    }

    var profilesURL: URL {
        return rootURL.appendingPathComponent("api/v1/profiles")
    }

    /**
     Initializes the Patient Data Manager with all required configuration.

     - Parameters:
         - rootURL: the root URL of the PDM server
         - clientId: the client ID to use for this client
         - clientSecret: the secret token to use
     */
    init(rootURL: URL, clientId: String, clientSecret: String) {
        self.rootURL = rootURL
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.healthKit = PDMHealthKit()
    }

    /**
     Initializes the Patient Data Manager using a configuration dictionary. This can be generated either via a PList or via a JSON file.

     - Parameter withConfig: the configuration to use
     */
    convenience init?(withConfig config: [String: Any]) {
        guard let urlString = config["RootURL"] as? String,
            let rootURL = URL(string: urlString),
            let clientId = config["ClientID"] as? String,
            let clientSecret = config["ClientSecret"] as? String else {
                return nil
        }
        self.init(rootURL: rootURL, clientId: clientId, clientSecret: clientSecret)
    }

    /**
     Sign into the PDM using the given account information.

     - Parameters:
         - email: the user's email address
         - password: the user's password
         - completionHandler: a closure to invoke when the request has completed
         - error: the error if an error occurred preventing the user from logging in, otherwise `nil` to indicate success
     */
    func signInAsUser(email: String, password: String, completionHandler: @escaping (_ error: Error?) -> Void) {
        // This uses the same token login the client login would use
        userClient.postJSONExpectingObject([ "email": email, "password": password, "grant_type": "password" ], to: oauthTokenURL) { json, response, error in
            guard let response = response else {
                completionHandler(error)
                return
            }
            guard let json = json else {
                completionHandler(PatientDataManagerError.couldNotUnderstandResponse)
                return
            }
            if response.statusCode == 401 {
                // This could be a login failure
                if let jsonError = json["error"] as? String, jsonError == "invalid_grant" {
                    completionHandler(PatientDataManagerError.loginFailed)
                    return
                }
            }
            // At this point request has to be a success or we should return an error
            guard error == nil else {
                completionHandler(error)
                return
            }
            guard let tokenType = json["token_type"] as? String, tokenType == "bearer", let accessToken = json["access_token"] as? String else {
                completionHandler(PatientDataManagerError.couldNotUnderstandResponse)
                return
            }
            self.userBearerToken = accessToken
            self.userClient.bearerToken = accessToken
            // Completed successfully
            completionHandler(nil)
        }
    }

    /**
     Signs out. This "always" succeeds in that the user information and user bearer token are cleared, but it can fail if the server can't be told to terminate the session.
     */
    func signOut(completionHandler: @escaping (Error?) -> Void) {
        user = nil
        userBearerToken = nil
        userClient.bearerToken = nil
        // For now, just instantly "complete"
        completionHandler(nil)
    }

    func createNewUserAccount(firstName: String, lastName: String, email: String, password: String, passwordConfirmation: String?, completionHandler: @escaping (PDMUser?, Error?) -> Void) {
        userClient.postJSONExpectingObject([
            "user": [
                "email": email,
                "first_name": firstName,
                "last_name": lastName,
                "password": password,
                "password_confirmation": passwordConfirmation ?? password
            ]
        ], to: usersURL) { json, response, error in
            guard let json = json, let response = response else {
                completionHandler(nil, error ?? PatientDataManagerError.couldNotUnderstandResponse)
                return
            }
            switch(response.statusCode) {
            case 201:
                // This is a success
                guard let user = PDMUser(fromJSON: json) else {
                    completionHandler(nil, PatientDataManagerError.couldNotUnderstandResponse)
                    return
                }
                self.user = user
                completionHandler(user, nil)
            // 422 means form errors
            case 422:
                if let errors = PatientDataManager.decodeErrors(json: json) {
                    completionHandler(nil, PatientDataManagerError.formInvalid(errors))
                } else {
                    fallthrough
                }
            default:
                completionHandler(nil, error ?? PatientDataManagerError.couldNotUnderstandResponse)
            }
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
                completionHandler(RESTError.serverReturnedError(httpResponse.statusCode))
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
                    self.clientBearerToken = jsonResponseDictionary["access_token"] as? String
                    if self.clientBearerToken != nil {
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

    /*
    /**
     Assuming the user is logged in, this gets the user information for their current account. If the user has already been loaded and reload is false, this immediately completes. Otherwise, it send an HTTP request to get the user information.
     - Parameters:
         - reload: whether to force a reload, defaults to false
         - completionHandler: the completion handler that receives notification that either the user information was loaded successfully or that an error prevented it from being loaded
     */
    func getUserInformation(reload: Bool=false, completionHandler: @escaping (PDMUser?, Error?) -> Void) {
        if !reload, let user = user {
            completionHandler(user, nil)
            return
        }
        userClient.getJSONObject(from: editUserURL) { json, response, error in
            guard error == nil else {
                // This indicates some internal error that means there is no response
                completionHandler(nil, error)
                return
            }
            guard let json = json, let user = PDMUser(fromJSON: json) else {
                completionHandler(nil, PatientDataManagerError.couldNotUnderstandResponse)
                return
            }
            self.user = user
            completionHandler(user, nil)
        }
    }
 */

    func getUserProfiles(completionHandler: @escaping ([PDMProfile]?, Error?) -> Void) {
        userClient.getJSON(from: profilesURL) { (json, response, error) in
            guard error == nil else {
                // This indicates some internal error that means there is no response
                completionHandler(nil, error)
                return
            }
            guard let jsonList = json as? [Any] else {
                completionHandler(nil, RESTError.responseJSONInvalid)
                return
            }
            let profiles = PDMProfile.profilesFromJSON(json: jsonList)
            // First is nil if the collection is empty, which is fine: if it's empty, we should set this to nil anyway
            self.activeProfile = profiles.first
            completionHandler(profiles, nil)
        }
    }

    func getActiveProfile(reload: Bool=false, completionHandler: @escaping (PDMProfile?, Error?) -> Void) {
        // Basically this is identical to getUserProfiles except it returns only one.
        if !reload, let activeProfile = activeProfile {
            completionHandler(activeProfile, nil)
        } else {
            getUserProfiles() { (profiles, error) in
                if let error = error {
                    completionHandler(nil, error)
                    return
                }
                // At this point active profiles should be set
                guard let activeProfile = self.activeProfile else {
                    completionHandler(nil, PatientDataManagerError.noResultFromServer)
                    return
                }
                completionHandler(activeProfile, nil)
            }
        }
    }

    func uploadHealthRecord(_ record: HKClinicalRecord, completionCallback: @escaping (Error?) -> Void) {
        let url = rootURL.appendingPathComponent("api/v1/$process-message")
        // The data should be a single resource which needs to be wrapped into a bundle
        let bundle = MessageBundle()
        if let pID = user?.id {
            bundle.addPatientId(String(pID))
        }
        do {
            try bundle.addRecordAsEntry(record)
            var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60.0)
            request.httpMethod = "POST"
            guard let token = clientBearerToken else {
                completionCallback(PatientDataManagerError.notLoggedIn)
                return
            }
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
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
                    completionCallback(RESTError.serverReturnedError(httpResponse.statusCode))
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
    static func decodeErrors(json: [String: Any]) -> [String: [String]]? {
        guard let errors = json["errors"],
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

/*
    // Internal function for handling a response. Note that this is called by the various utilities that send requests. The completionHandler will ALWAYS be called by this method and cannot be left out.
    internal func handleHTTPURLResponse(data: Data?, response: URLResponse?, error: Error?, completionHandler: @escaping (Data?, HTTPURLResponse?, Error?) -> Void) {
        if let error = error {
            completionHandler(nil, nil, error)
            return
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            completionHandler(nil, nil, PatientDataManagerError.internalError)
            return
        }
        // Handle various "standard errors"
        switch httpResponse.statusCode {
        case (100..<300):
            completionHandler(data, httpResponse, nil)
        case (300..<400):
            // This is a redirect of some form
            completionHandler(data, httpResponse, PatientDataManagerError.unhandledRedirect(httpResponse.statusCode))
        case 401:
            completionHandler(data, httpResponse, PatientDataManagerError.unauthorized)
        case 403:
            completionHandler(data, httpResponse, PatientDataManagerError.forbidden)
        case 404:
            completionHandler(data, httpResponse, PatientDataManagerError.missing)
        case 422:
            guard let unwrappedData = data, let mimeType = httpResponse.mimeType, MIMEType.isJSON(mimeType) else {
                // Not a 422 we can decode, return as a regular error
                completionHandler(data, httpResponse, PatientDataManagerError.serverReturnedError(httpResponse.statusCode))
                return
            }
            do {
                if let errors = try PatientDataManager.decodeErrors(unwrappedData) {
                    completionHandler(data, httpResponse, PatientDataManagerError.formInvalid(errors))
                    return
                }
            } catch {
                // Otherwise handle as normal
                completionHandler(data, httpResponse, PatientDataManagerError.serverReturnedError(httpResponse.statusCode))
            }
        default:
            // Anything else, just return as-is
            completionHandler(data, httpResponse, PatientDataManagerError.serverReturnedError(httpResponse.statusCode))
        }
    }
    */
}
