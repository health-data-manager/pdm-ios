//
//  PDMProfileTests.swift
//  pdm-uiTests
//
//  Created by Potter, Dan on 5/3/19.
//  Copyright © 2019 MITRE. All rights reserved.
//

import XCTest
@testable import pdm_ui

class PDMProfileTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testInitFromJSON() {
        let null = NSNull()
        let actualResult = PDMProfile.profilesFromJSON(json: [
            [
                "id": 127826653,
                "user_id": 1010081157,
                "patient_id": "c2871c97-ded2-4780-b59b-ba9a18012f99",
                "name": "Test User",
                "first_name": "Test",
                "last_name": "User",
                "gender": null,
                "dob": null,
                "created_at": "2019-03-15T19:32:29.539Z",
                "updated_at": "2019-03-15T19:32:29.539Z",
                "middle_name": null,
                "street": null,
                "city": null,
                "state": null,
                "zip": null,
                "relationship": null,
                "telephone": null,
                "telephone_use": null
            ],
            [
                "id": 127826652,
                "user_id": 1010081157,
                "patient_id": "e9a7da37-b040-4b3d-a248-934a6e301c73",
                "name": "Foo Bar",
                "first_name": "Foo",
                "last_name": "Bar",
                "gender": null,
                "dob": null,
                "created_at": "2019-03-15T19:31:14.998Z",
                "updated_at": "2019-03-15T19:31:14.998Z",
                 "middle_name": null,
                 "street": null,
                 "city": null,
                 "state": null,
                 "zip": null,
                 "relationship": null,
                 "telephone": null,
                 "telephone_use": null
            ]
        ])
        XCTAssertEqual(actualResult.count, 2)
        // Use XCTAssert and related functions to verify your tests produce the correct results.[]
    }

    func testParseJSON() {
        let jsonString = """
{
    "id":127826653,
    "user_id":1010081157,
    "patient_id":"c2871c97-ded2-4780-b59b-ba9a18012f99",
    "name":"Test User",
    "first_name":"Test",
    "last_name": "User",
    "gender":"male",
    "dob":null,
    "created_at":"2019-03-15T19:32:29.539Z",
    "updated_at":"2019-03-15T19:32:29.539Z",
    "middle_name":null,
    "street":null,
    "city":null,
    "state":null,
    "zip":null,
    "relationship":null,
    "telephone":null,
    "telephone_use":null
}
"""
        do {
            let json = try JSONSerialization.jsonObject(with: jsonString.data(using: .utf8)!, options: [])
            let profile = PDMProfile(withJSON: json as! [String: Any])
            XCTAssertNotNil(profile)
            if let profile = profile {
                // Check values
                XCTAssertEqual(profile.profileId, 127826653)
                XCTAssertEqual(profile.userId, 1010081157)
                XCTAssertEqual(profile.name, "Test User")
                XCTAssertEqual(profile.firstName, "Test")
                XCTAssertEqual(profile.lastName, "User")
            }
        } catch {
            XCTFail("Failed to create JSON")
        }
    }
}
