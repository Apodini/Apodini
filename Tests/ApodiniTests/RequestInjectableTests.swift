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
    
    var app: Application!
    
    override func setUp() {
        app = Application(.testing)
    }
    
    override func tearDown() {
        app.shutdown()
    }
    
    func testQueryParameterInjectable() throws {
        
        struct SomeComponent: Component {
            
            @QueryParameter(key: "query")
            var query: String
            
            func handle() -> String {
                "\(query)"
            }
        }
        
        let expectedQuery = "test"
        let request = Vapor.Request(application: app, url: "/some?query=\(expectedQuery)", on: app.eventLoopGroup.next())
        
        let response = try request
            .enterRequestContext(with: SomeComponent()) { component in
                component.handle().encodeResponse(for: request)
            }
            .wait()
        
        let responseData = try XCTUnwrap(response.body.data)
        let responseString = String(decoding: responseData, as: UTF8.self)
        XCTAssert(responseString == expectedQuery)
    }
    
}
