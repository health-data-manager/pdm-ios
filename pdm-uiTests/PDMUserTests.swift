//
//  PDMUserTests.swift
//  pdm-uiTests
//
//  Created by Potter, Dan on 9/9/19.
//  Copyright © 2019 MITRE. All rights reserved.
//

import XCTest
@testable import pdm_ui

class PDMUserTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testPasswordComplexity() {
        XCTAssertTrue(PDMUser.checkComplexityOfPassword("p45$w0rD"))
        XCTAssertFalse(PDMUser.checkComplexityOfPassword("password"))
        XCTAssertFalse(PDMUser.checkComplexityOfPassword("Ab1$"))
        // This is actually a kind of crummy password, but it should pass anyway
        XCTAssertTrue(PDMUser.checkComplexityOfPassword("!@#abcABC123"))
    }
}
