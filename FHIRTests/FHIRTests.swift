//
//  FHIRTests.swift
//  FHIRTests
//
//  Created by Potter, Dan on 9/17/19.
//  Copyright © 2019 MITRE. All rights reserved.
//

import XCTest
@testable import FHIR

class FHIRTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    func testParseDate() {
        guard let testDate = DateTime("2019-10-31") else {
            XCTFail("Date parse failed")
            return
        }
        XCTAssertNotNil(testDate.date)
        let calendar = Calendar(identifier: .gregorian)
        let parts = calendar.dateComponents([.year, .month, .day], from: testDate.date)
        XCTAssertNotNil(parts.year)
        XCTAssertEqual(parts.year, 2019)
        XCTAssertNotNil(parts.month)
        XCTAssertEqual(parts.month, 10)
        XCTAssertNotNil(parts.day)
        XCTAssertEqual(parts.day, 31)
    }
}
