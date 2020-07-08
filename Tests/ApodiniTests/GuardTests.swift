//
//  GuardTests.swift
//  
//
//  Created by Paul Schmiedmayer on 6/27/20.
//

import XCTest
import Vapor
@testable import Apodini


final class GuardTests: XCTestCase {
    struct TestGuard: Guard {
        func check(_ request: Vapor.Request) -> EventLoopFuture<Void> {
            print("Execute Guard")
            return request.eventLoop.makeSucceededFuture(Void())
        }
    }
    
    
    var component: some Component {
        Text("Hallo")
            .httpMethod(.GET)
            .guard(TestGuard())
            .httpMethod(.POST)
    }
    
    func testPrintComponent() {
        var printVisitor = PrintVisitor()
        if let visitableComponent = component as? Visitable {
            visitableComponent.visit(&printVisitor)
        }
    }
}

