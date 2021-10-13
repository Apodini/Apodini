//
//  ParameterMutabilityTests.swift
//  
//
//  Created by Max Obermeier on 04.01.21.
//

@testable import Apodini
import XCTApodini


class ParameterMutabilityTests: XCTApodiniDatabaseBirdTest {
    struct TestHandler: Handler {
        // variable
        @Parameter
        var name: String
        // constant
        @Parameter(.mutability(.constant))
        var times: Int
        // constant with default value
        @Parameter(.mutability(.constant))
        var separator: String = " "

        func handle() -> String {
            (1...times)
                    .map { _ in
                        "Hello \(name)!"
                    }
                    .joined(separator: separator)
        }
    }
    
    class StringClass: Codable {
        var string: String
        
        init(string: String) {
            self.string = string
        }
    }
    
    struct TestHandlerUsingClassType: Handler {
        @Parameter
        var projectName = StringClass(string: "Apodini")
        
        @Parameter
        var organizationName: StringClass? = StringClass(string: "Apodini")
        
        @Parameter
        var override = false
        
        func handle() -> String {
            if override {
                self.projectName.string = "NotApodini"
                self.organizationName?.string = "AlsoNotApodini"
            }
            
            if let organization = self.organizationName {
                return "\(organization.string)/\(projectName.string)"
            } else {
                return projectName.string
            }
        }
    }
    
    func testReduction() {
        XCTAssertEqual(Mutability.constant & Mutability.variable, .constant)
        XCTAssertEqual(Mutability.variable & Mutability.constant, .variable)
    }

    func testVariableCanBeChanged() throws {
        try XCTCheckHandler(TestHandler()) {
            MockRequest(expectation: "Hello Paul! Hello Paul! Hello Paul!") {
                NamedParameter("name", value: "Paul")
                NamedParameter("times", value: 3)
            }
            MockRequest<String> {
                NamedParameter("name", value: "Rudi")
            }
        }
    }
    
    func testConstantCannotBeChanged() throws {
        try XCTCheckHandler(TestHandler()) {
            MockRequest(expectation: "Hello Paul! Hello Paul! Hello Paul!") {
                NamedParameter("name", value: "Paul")
                NamedParameter("times", value: 3)
            }
            MockRequest<String>(expectation: .error) {
                NamedParameter("times", value: 4)
            }
        }
    }
    
    func testConstantWithDefaultCannotBeChanged() throws {
        try XCTCheckHandler(TestHandler()) {
            MockRequest(expectation: "Hello Paul! Hello Paul! Hello Paul!") {
                NamedParameter("name", value: "Paul")
                NamedParameter("times", value: 3)
            }
            MockRequest<String>()
        }

        try XCTCheckHandler(TestHandler()) {
            MockRequest(expectation: "Hello Paul! Hello Paul! Hello Paul!") {
                NamedParameter("name", value: "Paul")
                NamedParameter("times", value: 3)
            }
            MockRequest<String>(expectation: .error) {
                NamedParameter("separator", value: ", ")
            }
        }
    }
    
    func testMutationOnClassTypeDefaultParameterIsNotSharedBetweeConnectionContexts() throws {
        let handler = TestHandlerUsingClassType()
        
        // If a single connection context is used the Handler is kept in memory and therefore StringClass stays the same
        #warning("This might not be a desired behaviour, shouldn't this be reset to Apodini/Apodini as override is reset but the StringClass instances it not?")
        try XCTCheckHandler(TestHandlerUsingClassType()) {
            MockRequest(expectation: "AlsoNotApodini/NotApodini") {
                NamedParameter("override", value: true)
            }
            MockRequest(expectation: "AlsoNotApodini/NotApodini", options: .doNotReduceRequest)
        }
        
        // Using two different connection contexts showcases that sideeffects are not shared between different connection attempts.
        try XCTCheckHandler(handler) {
            MockRequest(expectation: "AlsoNotApodini/NotApodini") {
                NamedParameter("override", value: true)
            }
            MockRequest(expectation: "Apodini/Apodini", options: .doNotReuseConnection)
        }
    }
}
