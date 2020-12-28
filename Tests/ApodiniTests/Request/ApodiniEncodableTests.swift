//
//  ApodiniEncodableTests.swift
//  
//
//  Created by Moritz Schüll on 23.12.20.
//

import XCTest
@testable import Apodini

final class ApodiniEncodableTests: ApodiniTests, ApodiniEncodableVisitor {
    struct ActionComponent: Component {
        var message: String

        func handle() -> Action<String> {
            .final(message)
        }
    }

    static var expectedValue: String = ""

    override func setUpWithError() throws {
        try super.setUpWithError()
        ApodiniEncodableTests.expectedValue = ""
    }

    func visit<Element>(encodable: Element) where Element: Encodable {
        XCTFail("Visit for Encodable was called, when visit for Action should have been called")
    }

    func visit<Element>(action: Action<Element>) where Element: Encodable {
        switch action {
        case let .final(element):
            // swiftlint:disable:next force_cast
            XCTAssertEqual(element as! String, ApodiniEncodableTests.expectedValue)
        default:
            XCTFail("Expected value wrappen in .final")
        }
    }

    func callVisitor<C: Component>(_ component: C) {
        let result = component.handle()
        switch result {
        case let apodiniEncodable as ApodiniEncodable:
            apodiniEncodable.accept(self)
        default:
            XCTFail("Expected ApodiniEncodable")
        }
    }

    func testShouldCallAction() {
        ApodiniEncodableTests.expectedValue = "Action"
        callVisitor(ActionComponent(message: ApodiniEncodableTests.expectedValue))
    }
}
