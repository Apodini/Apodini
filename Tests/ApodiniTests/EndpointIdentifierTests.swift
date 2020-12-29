//
//  File.swift
//  
//
//  Created by Lukas Kollmer on 2020-12-29.
//

import Foundation
import XCTest
import Vapor
@testable import Apodini


final class EndpointIdentifierTests: ApodiniTests {
    struct TestHandlerType: IdentifiableHandler {
        typealias Response = Never
        let endpointId = ScopedEndpointIdentifier<Self>("main")
    }
    
    
    func testScopedEndpointIdentifier() {
        XCTAssertEqual(TestHandlerType().endpointId, AnyEndpointIdentifier("TestHandlerType.main"))
    }
    
    
    func testDefaultEndpointIdentifier() {
        struct TestWebService: WebService {
            var content: some Component {
                Text("a")
                Group("x") {
                    Text("b")
                }
                Group("x/y") {
                    Text("c")
                }
            }
        }
        
        let SSMBuilder = SharedSemanticModelBuilder(app)
        TestWebService().register(SSMBuilder)
        let allEndpoints = SSMBuilder.rootNode.collectAllEndpoints()
        
        XCTAssertEqual(allEndpoints.count, 3)
        
        print(allEndpoints.map(\.identifier.rawValue))
        
        XCTAssertTrue(allEndpoints.contains(where: { endpoint in
            endpoint.identifier.rawValue == "0:0:0"
                && endpoint.description == String(describing: Text("a"))
        }))
        XCTAssertTrue(allEndpoints.contains(where: { endpoint in
            endpoint.identifier.rawValue == "0:0:1:0"
                && endpoint.description == String(describing: Text("b"))
        }))
        XCTAssertTrue(allEndpoints.contains(where: { endpoint in
            endpoint.identifier.rawValue == "0:0:2:0"
                && endpoint.description == String(describing: Text("c"))
        }))
    }
}
