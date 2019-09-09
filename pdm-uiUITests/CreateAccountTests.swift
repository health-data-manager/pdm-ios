//
//  CreateAccountTests.swift
//  pdm-uiUITests
//
//  Created by Potter, Dan on 9/9/19.
//  Copyright © 2019 MITRE. All rights reserved.
//

import XCTest

class CreateAccountTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        let app = XCUIApplication()
        app.buttons["Create Account"].tap()

        let elementsQuery = app.scrollViews.otherElements
        let passwordSecureTextField = elementsQuery.children(matching: .secureTextField).matching(identifier: "Password").element(boundBy: 0)

        passwordSecureTextField.tap()
        passwordSecureTextField.typeText("bad password")

        let passwordStatusLabel = elementsQuery.staticTexts["passwordStatus"]
        XCTAssertEqual("Complexity requirement not met", passwordStatusLabel.label)
    }

}
