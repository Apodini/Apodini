//
//  ApodiniEncodableTests.swift
//  
//
//  Created by Moritz Schüll on 23.12.20.
//

import XCTest
@testable import Apodini

final class ApodiniEncodableTests: ApodiniTests, ApodiniEncodableVisitor {
    struct ActionHandler: Handler {
        var message: String

        func handle() -> Action<String> {
            .final(message)
        }
    }
    
    struct EncodableHandler: Handler {
        struct Message: ApodiniEncodable {
            let data: String
        }
        
        var message: Message

        func handle() -> Message {
            message
        }
    }
    
    enum EncodableType {
        case encodable
        case action
    }
    

    static var expectedValue: String = ""
    static var encodableType: EncodableType = .encodable
    
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        ApodiniEncodableTests.expectedValue = ""
    }

    func visit<Element>(encodable: Element) where Element: Encodable {
        guard ApodiniEncodableTests.encodableType == .encodable else {
            XCTFail("Visit for Encodable was called, when visit for Action should have been called")
            return
        }
        
        switch encodable {
        case let message as EncodableHandler.Message:
            XCTAssertEqual(message.data, ApodiniEncodableTests.expectedValue)
        default:
            XCTFail("Expected a well defined encodable type")
        }
    }

    func visit<Element>(action: Action<Element>) where Element: Encodable {
        guard ApodiniEncodableTests.encodableType == .action else {
            XCTFail("Visit for Action was called, when visit for Encodable should have been called")
            return
        }
        
        switch action {
        case let .final(element as String):
            XCTAssertEqual(element, ApodiniEncodableTests.expectedValue)
        default:
            XCTFail("Expected value wrappen in .final")
        }
    }

    func callVisitor<H: Handler>(_ handler: H) {
        let result = handler.handle()
        switch result {
        case let apodiniEncodable as ApodiniEncodable:
            apodiniEncodable.accept(self)
        default:
            XCTFail("Expected ApodiniEncodable")
        }
    }

    func testShouldCallAction() {
        ApodiniEncodableTests.expectedValue = "Action"
        ApodiniEncodableTests.encodableType = .action
        callVisitor(ActionHandler(message: ApodiniEncodableTests.expectedValue))
    }
    
    func testShouldCallEncodable() {
        ApodiniEncodableTests.expectedValue = "Encodable"
        ApodiniEncodableTests.encodableType = .encodable
        let message = EncodableHandler.Message(data: ApodiniEncodableTests.expectedValue)
        callVisitor(EncodableHandler(message: message))
    }
}
