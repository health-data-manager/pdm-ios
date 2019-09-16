//
//  RESTClient.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import Foundation

/// Errors that can be generated when sending/parsing REST requests
enum RESTError: Error, LocalizedError {
    /// An internal error occurred (generally this means that a URL could not be generated)
    case internalError

    /// Indicates that something prevented the request from being encoded
    case couldNotEncodeRequest(Error?)

    /// Indicate that the response could not be parsed as an expected document type
    case couldNotParseResponse

    /// The response was expected to be JSON, but JSON was not received
    case responseNotJSON

    /// While the response could be parsed as JSON, the JSON received was not correct
    case responseJSONInvalid

    /// Authorization was denied (potentially indicating that a bearer token has expired, 401 Unauthorized)
    case unauthorized

    /// The request was denied by the server (403 Forbidden)
    case forbidden

    /// A resource was missing (404 Not Found)
    case missing

    /// An unhandled redirect of some form
    case unhandledRedirect(Int)

    /// The server returned some variety of HTTP error code not handled above
    case serverReturnedError(Int)

    public var errorDescription: String? {
        switch self {
        case .internalError:
            return NSLocalizedString("An internal error prevented the request from being generated", comment: "Internal error")
        case .couldNotEncodeRequest(let causedBy):
            if let causedBy = causedBy {
                return String(format: NSLocalizedString("Could not encode the request due to an error: %@", comment: "Could not encode request"), causedBy.localizedDescription)
            } else {
                return NSLocalizedString("Could not encode the request.", comment: "Could not encode request")
            }
        case .couldNotParseResponse:
            return NSLocalizedString("Could not parse the result", comment: "Could not parse result")
        case .responseNotJSON:
            return NSLocalizedString("The response from the server was expected to be JSON, but it was not", comment: "Response not JSON")
        case .responseJSONInvalid:
            return NSLocalizedString("The response from the server was expected to be a specific JSON object, but it was a different JSON object", comment: "Response JSON Invalid")
        case .unauthorized:
            return NSLocalizedString("The server rejected the request because the client is not correctly logged in.", comment: "Unauthorized")
        case .forbidden:
            return NSLocalizedString("The server rejected the request because the client is forbidden from accessing it.", comment: "Forbidden")
        case .missing:
            return NSLocalizedString("The server indicated that the requested resource was not found.", comment: "Missing")
        case .unhandledRedirect(let statusCode):
            return String(format: NSLocalizedString("The server responded with a redirect (%d) that was never handled.", comment: "Unhandled redirect"), statusCode)
        case .serverReturnedError(let statusCode):
            var message: String
            switch(statusCode) {
            case 200..<300:
                message = NSLocalizedString("The server returned success but the response could not be handled properly.", comment: "HTTP 2xx")
            case 300..<400:
                message = NSLocalizedString("The server returned a redirect that was not followed.", comment: "HTTP 3xx")
            case 400:
                message = NSLocalizedString("The server could not understand the app's request.", comment: "HTTP 400")
            case 401:
                message = NSLocalizedString("The request was not authorized.", comment: "HTTP 401")
            case 403:
                message = NSLocalizedString("The server rejected the client request.", comment: "HTTP 403")
            case 404:
                message = NSLocalizedString("The server could not find the requested resource.", comment: "HTTP 404")
            case 402, 405..<500:
                message = NSLocalizedString("The server could not handle the request.", comment: "HTTP 4xx")
            case 500:
                message = NSLocalizedString("An internal error occurred within the PDM server.", comment: "HTTP 500")
            case 501:
                message = NSLocalizedString("The PDM server does not recognize the app's request.", comment: "HTTP 501")
            case 502:
                message = NSLocalizedString("The server, or a proxy server prior to the server, could not forward the request to the proper destination.", comment: "HTTP 502")
            case 503:
                message = NSLocalizedString("The server could not handle the request at this time.", comment: "HTTP 503")
            case 504:
                message = NSLocalizedString("The request timed out before the final server responded.", comment: "HTTP 504")
            case 505..<600:
                message = NSLocalizedString("An error occurred within the server.", comment: "HTTP 5xx")
            default:
                message = NSLocalizedString("An HTTP error occurred.", comment: "HTTP ???")
            }
            // And return with the error code
            return String(format: NSLocalizedString("%@ (HTTP %d)", comment: "HTTP format"), message, statusCode)
        }
    }
}

/**
 Class that provides a bunch of handlers for dealing with sending REST requests that send and receive JSON documents.
 */
class RESTClient {
    /// Headers that will be sent with every request
    var defaultHeaders = [String: String]()

    /// A bearer token. If set, this will be sent with every request in the Authorization header. While the bearer token can be retrieved, because of the way it's set, it has to take a substring and allocate a new string.
    var bearerToken: String? {
        get {
            if let token = defaultHeaders["Authorization"] {
                let header = "Bearer "
                if token.starts(with: header) {
                    return String(token[header.endIndex.samePosition(in: token)!...])
                }
            }
            // Otherwise there isn't one
            return nil
        }
        set(value) {
            if var value = value {
                if !value.starts(with: "Bearer ") {
                    value = "Bearer " + value
                }
                defaultHeaders["Authorization"] = value
            } else {
                defaultHeaders.removeValue(forKey: "Authorization")
            }
        }
    }
    var hasBearerToken: Bool {
        return defaultHeaders["Authorization"] != nil
    }

    /**
     Basic function to send a GET request to a given URL.

     - Parameters:
         - url: the URL to send the request to
         - queryItems: an optional set of query items that will be used to generate a query string in the given URL
         - completionHandler: closure to invoke when the form completes
         - data: the data from the response if any
         - response: the response from the server if any (may be `nil` if an error prevented the response from being received)
         - error: the error if any, if `nil` then `response` will be non-`nil` but there may be no data for some response types

     - Returns: the data task, if one was created, otherwise nil. When `nil` is returned, the callback handler will have been called with a specific error prior to the function completing.
     */
    @discardableResult func get(from url: URL, withQueryItems queryItems: [URLQueryItem]?=nil, completionHandler: @escaping (_ data: Data?, _ response: HTTPURLResponse?, _ error: Error?) -> Void) -> URLSessionDataTask? {
        var finalURL = url
        if let queryItems = queryItems {
            guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                completionHandler(nil, nil, RESTError.couldNotEncodeRequest(nil))
                return nil
            }
            components.queryItems = queryItems
            guard let generatedURL = components.url else {
                completionHandler(nil, nil, RESTError.couldNotEncodeRequest(nil))
                return nil
            }
            finalURL = generatedURL
        }
        return handleRequest(method: "GET", url: finalURL, data: nil, mimeType: nil, completionHandler: completionHandler)
    }

    @discardableResult func getJSON(from url: URL, withQueryItems queryItems: [URLQueryItem]?=nil, completionHandler: @escaping (_ jsonResponse: Any?, _ response: HTTPURLResponse?, _ error: Error?) -> Void) -> URLSessionDataTask? {
        return get(from: url, withQueryItems: queryItems) { (data, response, error) in
            guard let data = data, let mimeType = response?.mimeType, MIMEType.isJSON(mimeType) else {
                // If there is no data, or the response isn't JSON, just return whatever we have
                completionHandler(nil, response, error ?? RESTError.responseNotJSON)
                return
            }
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data, options: [])
                // If here, we're good
                completionHandler(jsonResponse, response, error)
                return
            } catch {
                // If here, we should pass the error on
                completionHandler(nil, response, error)
                return
            }
        }
    }

    @discardableResult func getJSONObject(from url: URL, withQueryItems queryItems: [URLQueryItem]?=nil, completionHandler: @escaping (_ jsonDictionary: [String: Any]?, _ response: HTTPURLResponse?, _ error: Error?) -> Void) -> URLSessionDataTask? {
        return getJSON(from: url, withQueryItems: queryItems) { (jsonResponse, response, error) in
            guard let jsonDictionary = jsonResponse as? [String: Any] else {
                completionHandler(nil, response, error ?? RESTError.couldNotParseResponse)
                return
            }
            completionHandler(jsonDictionary, response, error)
        }
    }

    /**
     Send a POST request with JSON that expects any content back.

     - Parameters:
         - url: the URL to get data from
         - json: JSON object to send (will be serialized via JSONSerialization)
         - completionHandler: the handler to call when the request completes
         - data: the data returned if any
         - response: the returned HTTP response, may only be `nil` if error is not `nil`
         - error: an error if one occurred. Note that this can be set in some "success" conditions as it will be set if the HTTP response was itself an error.

     - Returns: the data task, if one was created, otherwise nil. When `nil` is returned, the callback handler will have been called with a specific error prior to the function completing.
     */
    @discardableResult func post(to url: URL, withJSON json: Any, completionHandler: @escaping (Data?, HTTPURLResponse?, Error?) -> Void) -> URLSessionDataTask? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: json, options: [])
            return handleRequest(method: "POST", url: url, data: jsonData, mimeType: MIMEType.applicationJsonUTF8, completionHandler: completionHandler)
        } catch {
            completionHandler(nil, nil, RESTError.couldNotEncodeRequest(error))
            return nil
        }
    }

    /**
     Send a POST request with a traditional URL encoded form that expects any content back.

     - Parameters:
     - url: the URL to get data from
     - json: JSON object to send (will be serialized via JSONSerialization)
     - completionHandler: the handler to call when the request completes
     - data: the data returned if any
     - response: the returned HTTP response, may only be `nil` if error is not `nil`
     - error: an error if one occurred. Note that this can be set in some "success" conditions as it will be set if the HTTP response was itself an error.

     - Returns: the data task, if one was created, otherwise nil. When `nil` is returned, the callback handler will have been called with a specific error prior to the function completing.
     */
    @discardableResult func postForm(_ queryItems: [URLQueryItem], to url: URL, completionHandler: @escaping (Data?, HTTPURLResponse?, Error?) -> Void) -> URLSessionDataTask? {
        var components = URLComponents()
        components.queryItems = queryItems
        let data = components.query?.data(using: .utf8)
        return handleRequest(method: "POST", url: url, data: data, mimeType: MIMEType.applicationFormEncodedUTF8, completionHandler: completionHandler)
    }

    /**
     Send a POST request with JSON that expects a JSON object back.

     - Parameters:
         - url: the URL to get data from
         - json: JSON object to send (will be serialized via JSONSerialization)
         - completionHandler: the handler to call when the request completes
         - jsonResponse: the parsed JSON object, may only be `nil` if error is not `nil`
         - response: the returned HTTP response, may only be `nil` if error is not `nil`
         - error: an error if one occurred. Note that if `nil` then both the response and JSON must not be `nil`. However, if non-`nil`, then the response may still be non-`nil` if the error indicates an error dealing with the response, and the JSON may be non-`nil` if the response contained JSON. (Some HTTP errors will still return JSON describing the error.)

     - Returns: the data task, if one was created, otherwise nil. When `nil` is returned, the callback handler will have been called with a specific error prior to the function completing.
     */
    @discardableResult func postJSON(_ json: Any, to url: URL, completionHandler: @escaping (_ jsonResponse: Any?, _ response: HTTPURLResponse?, _ error: Error?) -> Void) -> URLSessionDataTask? {
        return post(to: url, withJSON: json) { (data, response, error) in
            guard let data = data else {
                completionHandler(nil, response, error ?? RESTError.responseNotJSON)
                return
            }
            // If we have data, try and parse it
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data, options: [])
                completionHandler(jsonResponse, response, error)
            } catch {
                completionHandler(nil, response, error)
            }
        }
    }

    /**
     A common requirement is to POST a JSON request and get a JSON object back. This handles that and guarantees that any parsed response is a JSON dictionary, setting an error if it is not.

     - Returns: the data task, if one was created, otherwise nil. When `nil` is returned, the callback handler will have been called with a specific error prior to the function completing.
     */
    @discardableResult func postJSONExpectingObject(_ json: Any, to url: URL, completionHandler: @escaping (_ jsonResponse: [String: Any]?, _ response: HTTPURLResponse?, _ error: Error?) -> Void) -> URLSessionDataTask? {
        return postJSON(json, to: url) { (json, response, error) in
            // Always try and convert the JSON object to a dictionary if we can
            guard let jsonDictionary = json as? [String: Any] else {
                // Return either the appropriate error (if there was one) or set response not valid
                completionHandler(nil, response, error ?? RESTError.responseJSONInvalid)
                return
            }
            // If there was an error, just let it be passed through as-is
            completionHandler(jsonDictionary, response, error)
        }
    }

    /**
     Generates a request object. Handles filling out a bunch of the standard fields.
     */
    func generateRequest(method: String, url: URL, data: Data?, mimeType: String?) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = data
        if let mimeType = mimeType {
            request.addValue(mimeType, forHTTPHeaderField: "Content-type")
        }
        for (header, value) in defaultHeaders {
            request.addValue(value, forHTTPHeaderField: header)
        }
        return request
    }

    /**
     Handles generating and executing a request.
     */
    func handleRequest(method: String, url: URL, data: Data?, mimeType: String?, completionHandler: @escaping (_ data: Data?, _ response: HTTPURLResponse?, _ error: Error?) -> Void) -> URLSessionDataTask {
        let request = generateRequest(method: method, url: url, data: data, mimeType: mimeType)
        // FOR DEBUGGING
        print(">> \(method) \(url)")
        if let headers = request.allHTTPHeaderFields {
            for (header, value) in headers {
                print("     \(header): \(value)")
            }
        }
        if let data = data {
            if let mimeType = mimeType {
                print("   Sending \(mimeType):")
            }
            print("   \(String(data: data, encoding: .utf8) ?? "could not encode data")")
        }
        // END DEBUGGING
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            self.handleHTTPURLResponse(data: data, response: response, error: error, completionHandler: completionHandler)
        }
        task.resume()
        return task
    }

    /// Function for handling a response. Note that this is called by the various utilities that send requests. The completionHandler will ALWAYS be called by this method and cannot be left out.
    func handleHTTPURLResponse(data: Data?, response: URLResponse?, error: Error?, completionHandler: @escaping (Data?, HTTPURLResponse?, Error?) -> Void) {
        if let error = error {
            // FOR DEBUGGING:
            print("<< ERROR \(error)")
            completionHandler(nil, nil, error)
            return
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            // FOR DEBUGGING:
            print("<< ERROR: not an HTTPURLResponse")
            completionHandler(nil, nil, RESTError.internalError)
            return
        }
        // FOR DEBUGGING
        print("<< HTTP \(httpResponse.statusCode)")
        if let mimeType = httpResponse.mimeType {
            print("   Received \(mimeType)")
            if let data = data, let dataAsString = String(data: data, encoding: .utf8) {
                print("   \(dataAsString)")
            } else {
                print("   (could not decode response")
            }
        }
        // END DEBUGGING
        // Handle various "standard errors"
        switch httpResponse.statusCode {
        case (100..<300):
            completionHandler(data, httpResponse, nil)
        case (300..<400):
            // This is a redirect of some form
            completionHandler(data, httpResponse, RESTError.unhandledRedirect(httpResponse.statusCode))
        case 401:
            completionHandler(data, httpResponse, RESTError.unauthorized)
        case 403:
            completionHandler(data, httpResponse, RESTError.forbidden)
        case 404:
            completionHandler(data, httpResponse, RESTError.missing)
        default:
            // Anything else, just return as-is
            completionHandler(data, httpResponse, RESTError.serverReturnedError(httpResponse.statusCode))
        }
    }
}
