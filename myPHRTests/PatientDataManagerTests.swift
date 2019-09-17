//
//  PatientDataManagerTests.swift
//  pdm-uiTests
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import XCTest
@testable import myPHR

class PatientDataManagerTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDecodeErrors() {
        let json = [
            "errors": [
                "email": ["is invalid"],
                "password":["is too short"]
            ]
        ]
        guard let errors = PatientDataManager.decodeErrors(json: json) else {
            XCTFail("Parsing failed")
            return
        }
        XCTAssertEqual(errors.count, 2)
        XCTAssertEqual(errors["email"], ["is invalid"])
        XCTAssertEqual(errors["password"], ["is too short"])
    }

    // This is more of a sanity check than anything else
    func testGeneratedURLs() {
        guard let localhost = URL(string: "http://localhost/") else {
            XCTFail("URL generation failed?")
            return
        }
        let pdm = PatientDataManager(rootURL: localhost)
        XCTAssertEqual("http://localhost/oauth/token", pdm.oauthTokenURL.absoluteString)
        XCTAssertEqual("http://localhost/users", pdm.usersURL.absoluteString)
        XCTAssertEqual("http://localhost/api/v1/profiles", pdm.profilesURL.absoluteString)
    }
}
