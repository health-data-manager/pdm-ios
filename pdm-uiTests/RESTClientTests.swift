//
//  RESTClientTests.swift
//  pdm-uiTests
//
//  Copyright © 2019 MITRE. All rights reserved.
//

import XCTest
@testable import pdm_ui

class RESTClientTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testBearerToken() {
        let client = RESTClient()
        client.bearerToken = "A Token"
        XCTAssertEqual(client.defaultHeaders["Authorization"], "Bearer A Token")
        XCTAssertEqual(client.bearerToken, "A Token")
        client.bearerToken = nil
        XCTAssertNil(client.defaultHeaders["Authorization"])
        XCTAssertNil(client.bearerToken)
    }

    func testAddingJavaScriptEscapes() {
        XCTAssertEqual("a string".addingJavaScriptEscapes(), "a string")
        XCTAssertEqual("\"a string\"".addingJavaScriptEscapes(), "\\\"a string\\\"")
        XCTAssertEqual("\"\'\\\r\n".addingJavaScriptEscapes(), "\\\"\\\'\\\\r\\n")
    }
}
