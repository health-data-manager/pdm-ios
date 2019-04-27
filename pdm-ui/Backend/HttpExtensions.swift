//
//  HttpExtensions.swift
//  pdm-ui
//
//  Copyright © 2019 MITRE. All rights reserved.
//
// A small little library to deal with common HTTP transactions

import Foundation

enum FormValue {
    case single(String)
    case multiple([String])
    // Add a value
    mutating func add(value: String) {
        switch self {
        case let .single(existing):
            self = .multiple([existing, value])
        case var .multiple(existing):
            existing.append(value)
        }
    }
}

enum HTTPFormError: Error {
    case couldNotFormatForm
    case internalError
    case serverError(Int)
}

// Generic HTTP request completion handler
func generateHttpCompletionHandler(_ handler: @escaping (Data?, HTTPURLResponse?, Error?) -> Void) -> (Data?, URLResponse?, Error?) -> Void {
    return { (data, response, error) in
        if let error = error {
            handler(nil, nil, error)
            return
        }
        guard let response = response else {
            handler(nil, nil, HTTPFormError.internalError)
            return
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            handler(nil, nil, HTTPFormError.internalError)
            return
        }
        // For debugging purposes: log the response
        print("Received HTTP \(httpResponse.statusCode) response for: \(httpResponse.url?.description ?? "unknown URL") with \(httpResponse.mimeType ?? "no MIME type given")")
        if let data = data {
            if let mimeType = httpResponse.mimeType {
                if mimeType == "application/json" || mimeType.starts(with: "application/json;") {
                    // Dump the contents as well
                    print("Response from server:")
                    if let json = String(data: data, encoding: .utf8) {
                        print(json)
                    } else {
                        print("Could not be decoded")
                    }
                }
            }
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            handler(data, httpResponse, HTTPFormError.serverError(httpResponse.statusCode))
            return
        }
        handler(data, httpResponse, nil)
    }
}

class HTTP {
    static func postTo(_ url: URL, withJSON json: Any, completionHandler: @escaping (Data?, HTTPURLResponse?, Error?) -> Void) throws {
        let request = try URLRequest.httpPostRequestTo(url, withJSON: json)
        let task = URLSession.shared.dataTask(with: request, completionHandler: generateHttpCompletionHandler(completionHandler))
        task.resume()
    }
}

class HTTPForm {
    // Taken from https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/encodeURIComponent
    static let formAllowedCharacters = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.!~*'()")
    var values = [String: FormValue]()

    init() {
    }

    init(withValues values: [String: String]) {
        for (key, value) in values {
            self.values[key] = FormValue.single(value)
        }
    }

    func addValue(_ value: String, for key: String) {
        // First see if there is already a value
        if var existing = values[key] {
            existing.add(value: value)
            // May have changed
            values[key] = existing
        } else {
            values[key] = FormValue.single(value)
        }
    }

    func getFrom(_ url: URL, completionHandler: @escaping (Data?, HTTPURLResponse?, Error?) -> Void) {
        guard let request = URLRequest.httpGetRequestTo(url, withForm: self) else {
            completionHandler(nil, nil, HTTPFormError.internalError)
            return
        }
        let task = URLSession.shared.dataTask(with: request, completionHandler: generateHttpCompletionHandler(completionHandler))
        task.resume()
    }

    // Handles creating a POST request and starting it and dealing with basic error handling
    func postTo(_ url: URL, completionHandler: @escaping (Data?, HTTPURLResponse?, Error?) -> Void) {
        guard let request = URLRequest.httpPostRequestTo(url, withForm: self) else {
            completionHandler(nil, nil, HTTPFormError.couldNotFormatForm)
            return
        }
        let task = URLSession.shared.dataTask(with: request, completionHandler: generateHttpCompletionHandler(completionHandler))
        task.resume()
    }

    func toApplicationFormEncoded() -> String {
        var result = ""
        for (key, value) in values {
            switch value {
            case let .single(formValue):
                result.appendApplicationFormValue(key: key, value: formValue)
            case let .multiple(formValues):
                for formValue in formValues {
                    result.appendApplicationFormValue(key: key, value: formValue)
                }
            }
        }
        return result
    }

    func toApplicationFormEncodedData() -> Data? {
        return toApplicationFormEncoded().data(using: .utf8)
    }

    static func applicationFormEncoded(key: String, value: String) -> String? {
        guard let k = key.addingPercentEncoding(withAllowedCharacters: HTTPForm.formAllowedCharacters),
            let v = value.addingPercentEncoding(withAllowedCharacters: HTTPForm.formAllowedCharacters) else {
                return nil
        }
        return "\(k)=\(v)"
    }
}

extension String {
    mutating func appendApplicationFormValue(key: String, value: String) {
        if let encoded = HTTPForm.applicationFormEncoded(key: key, value: value) {
            if !self.isEmpty {
                self.append("&")
            }
            self.append(encoded)
        }
    }
}

extension URLRequest {
    static var applicationFormEncoded = "application/x-www-form-urlencoded"

    static func httpGetRequestTo(_ url: URL, withForm form: HTTPForm) -> URLRequest? {
        guard let finalURL = URL(string: "?" + form.toApplicationFormEncoded(), relativeTo: url) else {
            return nil
        }
        var request = URLRequest(url: finalURL)
        request.httpMethod = "GET"
        return request
    }

    static func httpPostRequestTo(_ url: URL, withJSON json: Any) throws -> URLRequest {
        let jsonData = try JSONSerialization.data(withJSONObject: json, options: [])
        return URLRequest.httpPostRequestTo(url, withData: jsonData, ofMimeType: "application/json; charset=UTF-8")
    }

    static func httpPostRequestTo(_ url: URL, withForm form: HTTPForm) -> URLRequest? {
        guard let data = form.toApplicationFormEncodedData() else {
            return nil
        }
        return URLRequest.httpPostRequestTo(url, withData: data, ofMimeType: "application/x-www-form-urlencoded; charset=utf-8")
    }

    static func httpPostRequestTo(_ url: URL, withFormValues values: [String: String]) -> URLRequest? {
        return URLRequest.httpPostRequestTo(url, withForm: HTTPForm(withValues: values))
    }

    static func httpPostRequestTo(_ url: URL, withData data: Data, ofMimeType mimeType: String) -> URLRequest {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60.0)
        request.httpMethod = "POST"
        request.addValue(mimeType, forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        return request
    }
}
