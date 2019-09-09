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
        XCTAssert(PDMUser.checkComplexityOfPassword("p45$w0rD"))
        XCTAssert(PDMUser.checkComplexityOfPassword("password") == false)
        XCTAssert(PDMUser.checkComplexityOfPassword("Ab1$") == false)
        // This is actually a kind of crummy password, but it should pass anyway
        XCTAssert(PDMUser.checkComplexityOfPassword("!@#abcABC123"))
    }
}
