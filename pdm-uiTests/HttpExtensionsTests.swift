//
//  HttpExtensionsTests.swift
//  pdm-uiTests
//
//  Created by Potter, Dan on 4/23/19.
//  Copyright © 2019 MITRE. All rights reserved.
//

import XCTest
@testable import pdm_ui

class HttpExtensionsTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testFormValueAdd() {
        var f = FormValue.single("example")
        f.add(value: "other")
        switch f {
        case let .multiple(values):
            XCTAssertEqual(2, values.count)
            XCTAssertEqual("example", values[0])
            XCTAssertEqual("other", values[1])
        default:
            XCTFail("Did not get a FormValue.multiple")
        }
    }

    func testHttpForm() {
        let form = HTTPForm()
        form.addValue("value", for: "key")
        form.addValue("middle", for: "Key")
        form.addValue("other", for: "key")
        XCTAssertEqual("key=value&key=other&Key=middle", form.toApplicationFormEncoded())
    }

    func testFormEncoding() {
        var s = ""
        s.appendApplicationFormValue(key: "+=-;&", value: "~!@#$%^&*()-_=+")
        XCTAssertEqual("%2B%3D-%3B%26=~!%40%23%24%25%5E%26*()-_%3D%2B", s)
    }

    func testAppendApplicationFormValue() {
        var s = ""
        s.appendApplicationFormValue(key: "test", value: "value")
        XCTAssertEqual("test=value", s)
        s.appendApplicationFormValue(key: "another", value: "pair")
        XCTAssertEqual("test=value&another=pair", s)
    }

}
