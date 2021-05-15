//
//  PathParameterTests.swift
//  
//
//  Created by Paul Schmiedmayer on 12/3/20.
//

@testable import Apodini
import XCTest
import XCTApodini


final class PathParameterTests: XCTApodiniDatabaseBirdTest {
    struct TestComponent: Component {
        @PathParameter
        var name: String
        
        var content: some Component {
            Group($name) {
                TestHandler(name: $name)
            }
        }
    }
    
    
    struct TestHandler: Handler {
        @Binding
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
        let testHandler = try XCTUnwrap(testComponent.content.content as? TestHandler)
        
        let parameter = try XCTUnwrap(
            Mirror(reflecting: testHandler)
                .children
                .compactMap {
                    $0.value as? Binding<String>
                }
                .first
        )
        
        assert(testComponent.$name.parameterId == parameter.parameterId)
    }
    
    func testPassingPathComponents() throws {
        struct TestCompnent: Component {
            @PathParameter
            var pathIdentifier: String
            
            var content: some Component {
                Text("Hello Paul 👋")
            }
        }
        
        struct TestWebService: WebService {
            @PathParameter
            var pathParameter: String
            
            var content: some Component {
                TestCompnent(pathIdentifier: _pathParameter)
            }
        }
        
        let testService = TestWebService()
        let testComponent = try XCTUnwrap(testService.content as? TestCompnent)
        
        let testServicePathParameter = try XCTUnwrap(
            Mirror(reflecting: testService)
                .children
                .compactMap {
                    $0.value as? PathParameter<String>
                }
                .first
        )
        
        let testComponentPathParameter = try XCTUnwrap(
            Mirror(reflecting: testComponent)
                .children
                .compactMap {
                    $0.value as? PathParameter<String>
                }
                .first
        )
        XCTAssertEqual(testServicePathParameter.id, testComponentPathParameter.id)
        
        
        XCTAssertRuntimeFailure(testServicePathParameter.wrappedValue)
        XCTAssertRuntimeFailure(testComponentPathParameter.wrappedValue)
    }
}
