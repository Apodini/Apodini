//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import ApodiniUtils
@testable import Apodini
//@testable import ApodiniVaporSupport
@testable import ApodiniREST
import XCTest
import XCTApodini
import XCTApodiniNetworking


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
        
        TestWebService().start(app: app)
        
        
        //try app.vapor.app.test(.GET, "/v1/") { res in
        try app.testable().test(.GET, "/v1/") { res in
            XCTAssertEqual(res.status, .ok)
            
            struct Content: Decodable {
                let data: String
            }
            
            let content = try res.bodyStorage.getFullBodyData(decodedAs: Content.self)
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
        
        TestWebService().start(app: app)
        
        
        //try app.vapor.app.test(.GET, "/v1/") { res in
        try app.testable().test(.GET, "/v1/") { res in
            XCTAssertEqual(res.status, .ok)
            
            struct Content: Decodable {
                let data: String
            }
            
            let content = try res.bodyStorage.getFullBodyData(decodedAs: Content.self)
            XCTAssert(content.data == "Hello")
        }
    }
}
