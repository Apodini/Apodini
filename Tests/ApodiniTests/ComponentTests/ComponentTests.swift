//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import ApodiniUtils
@testable import Apodini
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
    
    
    
    func testAnyComponentTypeErasure() throws {
        struct TestWebService: WebService {
            var content: some Component {
                AnyComponent(Text("Hello"))
            }

            var configuration: any Configuration {
                REST()
            }
        }
        
        try TestWebService().start(app: app)
        
        try app.testable().test(.GET, "/") { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(try XCTUnwrapRESTResponseData(String.self, from: res), "Hello")
        }
    }
    
    
    func testAnyHandlerTypeErasure() throws {
        struct TestWebService: WebService {
            var content: some Component {
                AnyHandler(Text("Hello"))
            }
            
            var configuration: any Configuration {
                REST()
            }
        }
        
        try TestWebService().start(app: app)
        
        try app.testable().test(.GET, "/") { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(try XCTUnwrapRESTResponseData(String.self, from: res), "Hello")
        }
    }
}
