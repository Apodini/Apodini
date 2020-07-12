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
        @Apodini.Request
        var request: Vapor.Request
        
        func check() -> EventLoopFuture<Void> {
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
        let printVisitor = PrintVisitor()
        component.visit(printVisitor)
    }
}

