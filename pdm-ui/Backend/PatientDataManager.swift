//
//  PatientDataManager.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import Foundation
import HealthKit
import os.log

/// Various errors that can occur within the Patient Data Manager.
enum PatientDataManagerError: Error, LocalizedError {
    /// Some form of internal error prevented the request from being completed
    case internalError

    /// The response from the server could not be understood
    case couldNotUnderstandResponse

    /// The login attempt failed
    case loginFailed

    /// The user is not logged in so the given request does not make sense
    case notLoggedIn

    /// There is no active patient profile
    case noActiveProfile

    /// A form contained validation errors
    case formInvalid([String: [String]])

    /// A result was expected from the server but nothing was returned
    case noResultFromServer

    /// A request was made that requires HealthKit but HealthKit is not available on this device
    case healthKitNotAvailable

    /// The configuration of the PDM is invalid
    case invalidConfiguration

    public var errorDescription: String? {
        switch self {
        case .internalError:
            return NSLocalizedString("An internal error occurred", comment: "Internal Error")
        case .couldNotUnderstandResponse:
            return NSLocalizedString("Could not understand response from server.", comment: "Could not understand response")
        case .loginFailed:
            return NSLocalizedString("Login failed (email and password were not accepted).", comment: "Login failed")
        case .notLoggedIn:
            return NSLocalizedString("Request cannot be completed because the client is not logged into the server.", comment: "Not logged in")
        case .noActiveProfile:
            return NSLocalizedString("There is no active patient profile.", comment: "No active profile")
        case .formInvalid(_):
            return NSLocalizedString("The server rejected the request because of errors in the provided values.", comment: "Form invalid")
        case .noResultFromServer:
            return NSLocalizedString("No object was returned by the server.", comment: "No result from server")
        case .healthKitNotAvailable:
            return NSLocalizedString("HealthKit is not available on this device.", comment: "HealthKit not available")
        case .invalidConfiguration:
            return NSLocalizedString("The internal configuration of the application is invalid.", comment: "Invalid configuration")
        }
    }
}

extension Notification.Name {
    /// A notification that is sent out when the PDM health records have changed and should be reloaded
    static let healthRecordsChanged = Notification.Name("pdmHealthRecordsChanged")
}

/// Supported record types.
enum PDMRecordType: CaseIterable {
    case allergy
    case appointment
    case careplan
    case condition
    case disease
    case healthReceipt
    case immunization
    case lab
    case medication
    case procedure
    case vital

    var name: String {
        switch self {
        case .allergy:
            return "Allergy"
        case .appointment:
            return "Appointment"
        case .careplan:
            return "CarePlan"
        case .condition:
            return "Condition"
        case .disease:
            return "Disease"
        case .healthReceipt:
            return "HealthReceipt"
        case .immunization:
            return "Immunization"
        case .lab:
            return "Lab"
        case .medication:
            return "Medication"
        case .procedure:
            return "Procedure"
        case .vital:
            return "Vital"
        }
    }

    var cssName: String {
        switch self {
        case .allergy:
            return "allergy"
        case .appointment:
            return "appointment"
        case .careplan:
            return "care-plan"
        case .condition:
            return "condition"
        case .disease:
            return "disease"
        case .healthReceipt:
            return "health-receipt"
        case .immunization:
            return "immunization"
        case .lab:
            return "lab"
        case .medication:
            return "medication"
        case .procedure:
            return "procedure"
        case .vital:
            return "vital"
        }
    }
}

/// The PatientDataManager object. This is intended to be a singleton that represents the connection to the PatientDataManager web server. Conceptually multiple instances could exist that provide connections to different PDMs.
class PatientDataManager {
    /// The root server URL, configured when the PDM object is created
    let rootURL: URL

    /// The client ID, configured when the PDM object is created.
    let clientId: String

    /// The client secret, configured when the PDM object is created.
    let clientSecret: String

    /// Optional HealthKit support. If the current device does not support HealthKit, this will be `nil`.
    let healthKit: PDMHealthKit?

    /// Client for user requests
    let userClient = RESTClient()

    /// Client for FHIR requests (sending records to the PDM)
    let fhirClient = RESTClient()

    /// Whether or not auto login has been enabled within the client configuration. Defaults to false.
    var autoLogin = false

    /// The current user information. This does not appear to be exposed via the PDM backend REST API so this should probably not be relied on.
    var user: PDMUser?
    /**
     The currently active profile. While there can be multiple users associated with an account, health information is only shown from a single active profile.

     Note that this can be nil if it hasn't been loaded yet. Use getActiveProfile to guarantee it's loaded.
     */
    var activeProfile: PDMProfile?

    /// A bundle of loaded records from the server. This will probably be changed at some future point.
    var serverRecords: FHIRBundle?

    // Generated URLs.

    /// The OAuth token URL (relative to the root URL)
    var oauthTokenURL: URL {
        return rootURL.appendingPathComponent("oauth/token")
    }

    /// The URL for logging in as a user
    var usersURL: URL {
        return rootURL.appendingPathComponent("users")
    }

    lazy var apiURL = rootURL.appendingPathComponent("api/v1")

    /// The URL for retrieving profiles
    var profilesURL: URL {
        return apiURL.appendingPathComponent("profiles")
    }

    /**
     Initializes the Patient Data Manager with all required configuration.

     - Parameters:
         - rootURL: the root URL of the PDM server
         - clientId: the client ID to use for this client
         - clientSecret: the secret token to use
         - ignoreHealthKit: if set to true, HealthKit support will be disabled even if it exists on the current device
     */
    init(rootURL: URL, clientId: String, clientSecret: String, ignoreHealthKit: Bool=false) {
        self.rootURL = rootURL
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.healthKit = ignoreHealthKit ? nil : PDMHealthKit()
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
        let ignoreHealthKit = (config["DisableHealthKit"] as? Bool) ?? false
        if ignoreHealthKit {
            print("Ignoring HealthKit (based on client settings)")
        }
        self.init(rootURL: rootURL, clientId: clientId, clientSecret: clientSecret, ignoreHealthKit: ignoreHealthKit)
        self.autoLogin = (config["AutoLogin"] as? Bool) ?? false
    }

    /**
     Sign into the PDM using the given account information.

     - Parameters:
         - email: the user's email address
         - password: the user's password
         - completionHandler: a closure to invoke when the request has completed
         - error: the error if an error occurred preventing the user from logging in, otherwise `nil` to indicate success
     */
    @discardableResult func signInAsUser(email: String, password: String, completionHandler: @escaping (_ error: Error?) -> Void) -> URLSessionTask? {
        // This uses the same token login the client login would use
        return userClient.postJSONExpectingObject([ "email": email, "password": password, "grant_type": "password" ], to: oauthTokenURL) { json, response, error in
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
            guard let tokenType = json["token_type"] as? String, tokenType.caseInsensitiveCompare("bearer") == .orderedSame, let accessToken = json["access_token"] as? String else {
                completionHandler(PatientDataManagerError.couldNotUnderstandResponse)
                return
            }
            self.userClient.bearerToken = accessToken
            // Completed successfully
            completionHandler(nil)
        }
    }

    /// Signs out. This "always" succeeds in that the user information and user bearer token are cleared, but it can fail if the server can't be told to terminate the session.
    ///
    /// - Parameter completionHandler: handler invoked when the logout completes
    func signOut(completionHandler: @escaping (Error?) -> Void) {
        user = nil
        userClient.bearerToken = nil
        activeProfile = nil
        serverRecords = nil
        // For now, just instantly "complete" - in the future this should try and expire the session on the server, too
        completionHandler(nil)
    }

    /// Invoke the create new user account endpoint on the backend.
    ///
    /// - Parameters:
    ///   - firstName: the user's first name
    ///   - lastName: the user's last name
    ///   - email: the user's email address
    ///   - password: the (unencrypted) password
    ///   - passwordConfirmation: a second copy of the password, for verifying it's entered correctly (if left nil, `password` is sent for this)
    ///   - completionHandler: a callback to receive information on the success of the call
    ///   - user: the created user, if the account was successfully created
    ///   - error: the error that prevented the account from being created
    /// - Returns: a task indicating progress if the request was sent (or nil if an error prevented it from being sent, the details of which will be sent to the callback)
    @discardableResult func createNewUserAccount(firstName: String, lastName: String, email: String, password: String, passwordConfirmation: String?, completionHandler: @escaping (_ user: PDMUser?, _ error: Error?) -> Void) -> URLSessionTask? {
        return userClient.postJSONExpectingObject([
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
    func fhirClientLogin(completionHandler: @escaping (Error?) -> Void) {
        fhirClient.postForm([
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "client_secret", value: clientSecret),
            URLQueryItem(name: "grant_type", value: "client_credentials")
        ], to: oauthTokenURL) { data, response, error in
            if let error = error {
                completionHandler(error)
                return
            }
            guard let response = response, let mimeType = response.mimeType, MIMEType.isJSON(mimeType), let data = data else {
                completionHandler(PatientDataManagerError.couldNotUnderstandResponse)
                return
            }
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data, options: [])
                guard let jsonResponseDictionary = jsonResponse as? [String: Any],
                    let tokenType = jsonResponseDictionary["token_type"] as? String,
                    tokenType.caseInsensitiveCompare("Bearer") == .orderedSame else {
                        completionHandler(PatientDataManagerError.couldNotUnderstandResponse)
                        return
                }
                guard let bearerToken = jsonResponseDictionary["access_token"] as? String else {
                    self.fhirClient.bearerToken = nil
                    completionHandler(PatientDataManagerError.couldNotUnderstandResponse)
                    return
                }
                self.fhirClient.bearerToken = bearerToken
                completionHandler(nil)
                return
            } catch {
                completionHandler(error)
                return
            }
        }
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
            guard let jsonList = json as? [Any],
                let profiles = PDMProfile.profilesFromJSON(json: jsonList) else {
                    completionHandler(nil, RESTError.responseJSONInvalid)
                    return
            }
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

    @discardableResult func uploadHealthRecords(_ records: [HKClinicalRecord], completionCallback: @escaping (Error?) -> Void) -> URLSessionDataTask? {
        guard fhirClient.hasBearerToken else {
            completionCallback(PatientDataManagerError.notLoggedIn)
            return nil
        }
        let url = rootURL.appendingPathComponent("api/v1/$process-message")
        // The data should be a single resource which needs to be wrapped into a bundle
        let bundle = MessageBundle()
        guard let pID = activeProfile?.profileId else {
            completionCallback(PatientDataManagerError.noActiveProfile)
            return nil
        }
        bundle.addPatientId(String(pID))
        do {
            try bundle.addRecordsAsEntry(records)
            return fhirClient.post(to: url, withJSON: bundle.createJSON()) { data, response, error in
                completionCallback(error)
            }
        } catch {
            // Q: Is this really an error?
            completionCallback(error)
            return nil
        }
    }

    /// Attempts to upload any health records.
    func uploadHealthRecordsFromHealthKit(completionCallback: @escaping (Error?) -> Void) {
        guard let healthKit = healthKit else {
            completionCallback(PatientDataManagerError.healthKitNotAvailable)
            return
        }
        healthKit.queryAllHealthRecords() { records, error in
            if let error = error {
                completionCallback(error)
                return
            }
            guard let records = records else {
                completionCallback(PatientDataManagerError.internalError)
                return
            }
            self.uploadHealthRecords(records, completionCallback: completionCallback)
        }
    }

    /**
     Load health records from the patient data manager.
     - Parameters:
         - completionCallback: the completion handler invoked when the operation completes
         - bundle: the resulting FHIR bundle if the load was successful
         - error: an error object describing why the load failed
     - Returns: a URLSessionTask describing the load progress
     */
    @discardableResult func loadHealthRecords(completionCallback: @escaping (_ bundle: FHIRBundle?, _ error: Error?) -> Void) -> URLSessionTask? {
        guard userClient.hasBearerToken else {
            completionCallback(nil, PatientDataManagerError.notLoggedIn)
            return nil
        }
        guard let profile = activeProfile else {
            completionCallback(nil, PatientDataManagerError.noActiveProfile)
            return nil
        }
        return userClient.getJSONObject(from: rootURL.appendingPathComponent("api/v1/Patient/\(profile.profileId)/$everything")) { data, response, error in
            if let error = error {
                completionCallback(nil, error)
            } else {
                guard let json = data else {
                    completionCallback(nil, PatientDataManagerError.noResultFromServer)
                    return
                }
                guard let bundle = FHIRBundle(fromJSON: json) else {
                    print("Could not parse FHIR bundle")
                    completionCallback(nil, PatientDataManagerError.couldNotUnderstandResponse)
                    return
                }
                self.serverRecords = bundle
                completionCallback(bundle, nil)
            }
        }
    }

    /**
     Load all providers from the patient data manager.
     - Parameters:
         - completionCallback: the completion handler invoked when the operation completes
         - providers: the resulting list of providers, or `nil` if there was an error
         - error: an error object describing why the load failed if it failed
     - Returns: a URLSessionTask describing the load progress
     */
    @discardableResult func loadAllProviders(completionCallback: @escaping (_ providers: [PDMProvider]?, _ error: Error?) -> Void) -> URLSessionTask? {
        guard userClient.hasBearerToken else {
            completionCallback(nil, PatientDataManagerError.notLoggedIn)
            return nil
        }
        return userClient.getJSON(from: apiURL.appendingPathComponent("providers")) { data, response, error in
            if let error = error {
                completionCallback(nil, error)
                return
            }
            guard let json = data else {
                completionCallback(nil, PatientDataManagerError.noResultFromServer)
                return
            }
            guard let jsonArray = json as? [Any], let providers = PDMProvider.providers(fromJSON: jsonArray) else {
                completionCallback(nil, PatientDataManagerError.couldNotUnderstandResponse)
                return
            }
            completionCallback(providers, nil)
        }
    }

    /**
     Load providers that have already been connected to a given profile from the patient data manager.
     - Parameters:
         - completionCallback: the completion handler invoked when the operation completes
         - providerLinks: the resulting list of provider links, or `nil` if there was an error
         - error: an error object describing why the load failed if it failed
     - Returns: a URLSessionTask describing the load progress
     */
    @discardableResult func loadProvidersConnectedTo(_ profile: PDMProfile, completionCallback: @escaping (_ providerLinks: [PDMProviderProfileLink]?, _ error: Error?) -> Void) -> URLSessionTask? {
        guard userClient.hasBearerToken else {
            completionCallback(nil, PatientDataManagerError.notLoggedIn)
            return nil
        }
        return userClient.getJSON(from: apiURL.appendingPathComponent("profiles/\(profile.profileId)/providers")) { data, response, error in
            if let error = error {
                completionCallback(nil, error)
                return
            }
            guard let json = data else {
                completionCallback(nil, PatientDataManagerError.noResultFromServer)
                return
            }
            guard let jsonArray = json as? [Any], let providerLinks = PDMProviderProfileLink.list(fromJSON: jsonArray) else {
                completionCallback(nil, PatientDataManagerError.couldNotUnderstandResponse)
                return
            }
            completionCallback(providerLinks, nil)
        }
    }

    @discardableResult func linkToProvider(_ provider: PDMProvider, redirectURI: String, completionHandler: @escaping (_ oauthURL: URL?, _ error: Error?) -> Void) -> URLSessionTask? {
        guard let profile = activeProfile else {
            completionHandler(nil, PatientDataManagerError.noActiveProfile)
            return nil
        }
        // Just need the API root
        return userClient.postJSONExpectingObject([
            "provider_id": provider.id,
            "redirect_uri": redirectURI
        ], to: apiURL.appendingPathComponent("profiles/\(profile.profileId)/providers")) { data, response, error in
            if let error = error {
                completionHandler(nil, error)
                return
            }
            guard let data = data, let redirectString = data["redirect_uri"] as? String, let redirectURI = URL(string: redirectString) else {
                completionHandler(nil, PatientDataManagerError.couldNotUnderstandResponse)
                return
            }
            completionHandler(redirectURI, nil)
        }
    }

    @discardableResult func linkToProviderOauthCallback(_ provider: PDMProvider, code: String, redirectURI: String, completionHandler: @escaping (_ error: Error?) -> Void) -> URLSessionTask? {
        guard let profile = activeProfile else {
            completionHandler(PatientDataManagerError.noActiveProfile)
            return nil
        }
        return userClient.getJSONObject(from: rootURL.appendingPathComponent("oauth/callback"), withQueryItems: [
            URLQueryItem(name: "state", value: "\(provider.id):\(profile.profileId)"),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "redirect_uri", value: redirectURI)
        ]) { data, response, error in
            if let error = error {
                completionHandler(error)
                return
            }
            completionHandler(nil)
        }
    }

    /// Attempts to decode a JSON object that describes form errors
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
}
