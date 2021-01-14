//
//  ComponentTests.swift
//  
//
//  Created by Paul Schmiedmayer on 1/2/21.
//

@testable import Apodini
import XCTest
import XCTApodini


class ComponentTests: ApodiniTests {
    func testAssertTypeIsStruct() throws {
        class TestClass {}
        XCTAssertRuntimeFailure(assertTypeIsStruct(TestClass.self))
        
        enum TestEnum {}
        XCTAssertRuntimeFailure(assertTypeIsStruct(TestEnum.self))
        
        struct TestStruct {}
        assertTypeIsStruct(TestStruct.self)
        
        XCTAssertRuntimeFailure(assertTypeIsStruct(Never.self))
        XCTAssertRuntimeFailure(assertTypeIsStruct((() -> Void).self))
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
        }
        
        TestWebService.main(app: app)
        
        
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
        }
        
        TestWebService.main(app: app)
        
        
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
