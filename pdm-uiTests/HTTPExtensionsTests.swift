//
//  HttpExtensionsTests.swift
//  pdm-uiTests
//
//  Created by Potter, Dan on 4/23/19.
//  Copyright © 2019 MITRE. All rights reserved.
//

import XCTest
@testable import pdm_ui

class HTTPExtensionsTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testMIMETypeWithoutAttributes() {
        let type = MIMEType("application/json")
        XCTAssertEqual(type.type, "application/json")
        XCTAssertEqual(type.attributes.count, 0)
    }

    func testMIMETypeWithAttributes() {
        let type = MIMEType("application/json; charset=UTF-8")
        XCTAssertEqual(type.type, "application/json")
        XCTAssertEqual(type.attributes.count, 1)
        XCTAssertEqual(type.attributes["charset"], "UTF-8")
    }
}
