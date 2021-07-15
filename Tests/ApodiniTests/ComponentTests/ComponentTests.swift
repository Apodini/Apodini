//
//  ComponentTests.swift
//  
//
//  Created by Paul Schmiedmayer on 1/2/21.
//

import ApodiniUtils
@testable import Apodini
@testable import ApodiniVaporSupport
@testable import ApodiniREST
import XCTest
import XCTApodini


class ComponentTests: ApodiniTests {
    func testPreconditionTypeIsStruct() throws {
        class TestClass {}
        XCTAssertRuntimeFailure(preconditionTypeIsStruct(TestClass.self))
        
        enum TestEnum {}
        XCTAssertRuntimeFailure(preconditionTypeIsStruct(TestEnum.self))
        
        struct TestStruct {}
        preconditionTypeIsStruct(TestStruct.self)
        
        XCTAssertRuntimeFailure(preconditionTypeIsStruct(Never.self))
        XCTAssertRuntimeFailure(preconditionTypeIsStruct((() -> Void).self))
    }
    
    func testTupleComponentErrors() throws {
        struct NoComponent {}
        let failingTupleComponent = TupleComponent((NoComponent(), NoComponent()))
        let syntaxTreeVisitor = SyntaxTreeVisitor()
        XCTAssertRuntimeFailure(failingTupleComponent.accept(syntaxTreeVisitor))
    }
    
    func testAnyComponentTypeErasure() throws {
        struct TestWebService: WebService {
            var content: some Component {
                AnyComponent(Text("Hello"))
            }

            var configuration: Configuration {
                REST()
            }
        }
        
        TestWebService.start(app: app)
        
        
        try app.vapor.app.test(.GET, "/v1/") { res in
            XCTAssertEqual(res.status, .ok)
            
            struct Content: Decodable {
                let data: String
            }
            
            let content = try res.content.decode(Content.self)
            XCTAssert(content.data == "Hello")
        }
    }
    
    func testAnyHandlerTypeErasure() throws {
        struct TestWebService: WebService {
            var content: some Component {
                AnyHandler(Text("Hello"))
            }
            
            var configuration: Configuration {
                REST()
            }
        }
        
        TestWebService.start(app: app)
        
        
        try app.vapor.app.test(.GET, "/v1/") { res in
            XCTAssertEqual(res.status, .ok)
            
            struct Content: Decodable {
                let data: String
            }
            
            let content = try res.content.decode(Content.self)
            XCTAssert(content.data == "Hello")
        }
    }
}
