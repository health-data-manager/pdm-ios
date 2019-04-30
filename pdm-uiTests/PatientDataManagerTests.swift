//
//  PatientDataManagerTests.swift
//  pdm-uiTests
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import XCTest
@testable import pdm_ui

class PatientDataManagerTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDecodeErrors() {
        let json = """
            {"errors":{"email":["is invalid"],"password":["is too short"]}}
"""
        do {
            guard let errors = try PatientDataManager.decodeErrors(json.data(using: .utf8)!) else {
                XCTFail("Parsing failed")
                return
            }
            XCTAssertEqual(errors.count, 2)
            XCTAssertEqual(errors["email"], ["is invalid"])
            XCTAssertEqual(errors["password"], ["is too short"])
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }
}
