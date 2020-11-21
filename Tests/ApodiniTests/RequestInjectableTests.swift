//
//  RequestInjectableTests.swift
//  
//
//  Created by Lorena Schlesinger on 21.11.20.
//

import XCTest
import Vapor
@testable import Apodini

final class RequestInjectableTests: XCTestCase {
    
    func testQueryParameterInjectable() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
               
        struct SomeComponent: Component {
            
            @QueryParameter(key: "query")
            var query: String
            
            func handle() -> String {
                "\(query)"
            }
        }
        
        let expectedQueryKey = "query"
        let expectedQueryValue = "test"
        
        app.routes.get("some") {req in
            req.enterRequestContext(with: SomeComponent()) { component in
                return component.handle().encodeResponse(for: req)
            }
        }
        
        try app.testable().test(.GET, "/some?\(expectedQueryKey)=\(expectedQueryValue)") { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, expectedQueryValue)
        }
    }
    
    func testPathParameterInjectable() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        
        struct SomeComponent: Component {
            
            @PathParameter(key: "pathId")
            var pathId: String
            
            func handle() -> String {
                "\(pathId)"
            }
        }
        
        let expectedPathParameter = "123"
        
        app.routes.get("some", ":pathId") {req in
            req.enterRequestContext(with: SomeComponent()) { component in
                return component.handle().encodeResponse(for: req)
            }
        }
        
        try app.testable().test(.GET, "/some/\(expectedPathParameter)") { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, expectedPathParameter)
        }
    }
    
}
