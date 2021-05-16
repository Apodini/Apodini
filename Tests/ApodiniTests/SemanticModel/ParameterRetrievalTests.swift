//
// Created by Andreas Bauer on 25.12.20.
//

@testable import Apodini
import XCTApodini


class ParameterRetrievalTests: XCTApodiniDatabaseBirdTest {
    struct TestHandler: Handler {
        @Parameter
        var name: String
        @Parameter
        var times: Int?
        @Parameter
        var separator: String = " "
        @Parameter
        var prefix: String? = "Standard Prefix"


        func handle() -> String {
            (prefix ?? "") + (1...(times ?? 1))
                    .map { _ in
                        "Hello \(name)!"
                    }
                    .joined(separator: separator)
        }
    }
    
    func testParameterRetrieval() throws {
        try XCTCheckHandler(TestHandler()) {
            MockRequest(expectation: "👋 Hello Paul!") {
                NamedParameter("name", value: "Paul")
                NamedParameter("prefix", value: "👋 ")
            }
        }
        
        try XCTCheckHandler(TestHandler()) {
            MockRequest(expectation: "Standard PrefixHello Paul!-Hello Paul!-Hello Paul!") {
                NamedParameter("name", value: "Paul")
                NamedParameter("times", value: 3)
                NamedParameter("separator", value: "-")
            }
        }
    }

    func testParameterExplicitNilRetrieval() throws {
        try XCTCheckHandler(TestHandler()) {
            MockRequest(expectation: "Hello Paul!") {
                NamedParameter("name", value: "Paul")
                NamedParameter<Int>("times", value: nil)
                NamedParameter<String>("prefix", value: nil)
            }
        }
        
        try XCTCheckHandler(TestHandler()) {
            MockRequest(expectation: "Hello Paul! Hello Paul! Hello Paul!") {
                NamedParameter("name", value: "Paul")
                NamedParameter("times", value: 3)
                NamedParameter<String>("prefix", value: nil)
            }
        }
    }
}
