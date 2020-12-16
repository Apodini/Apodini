//
//  PathParameterTests.swift
//  
//
//  Created by Paul Schmiedmayer on 12/3/20.
//

@testable import Apodini
import XCTest


final class PathParameterTests: XCTestCase {
    struct TestComponent: EndpointProvidingNode {
        @PathParameter
        var name: String
        
        var content: some EndpointProvidingNode {
            Group($name) {
                TestHandler(name: $name)
            }
        }
    }
    
    
    struct TestHandler: EndpointNode {
        @Parameter
        var name: String
        
        @Parameter
        var times: Int
        
        func handle() -> String {
            (0...times)
                .map { _ in
                    "Hello \(name)!"
                }
                .joined(separator: " ")
        }
    }
    
    
    func testPrintComponent() throws {
        let testComponent = TestComponent()
        let testHandler = try XCTUnwrap((testComponent.content.content as? _WrappedEndpoint<TestHandler>)?.endpoint)
        
        let parameter = try XCTUnwrap(
            Mirror(reflecting: testHandler)
                .children
                .compactMap {
                    $0.value as? Parameter<String>
                }
                .first
        )
        
        assert(testComponent.$name.id == parameter.id)
    }
}
