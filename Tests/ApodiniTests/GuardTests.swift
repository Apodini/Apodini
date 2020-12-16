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
    struct TestGuard: SyncGuard {
        @_Request
        var request: Vapor.Request
        
        func check() {
            request.logger.info("Execute Guard")
        }
    }
    
    
    var component: some EndpointNode {
        Text("Hallo")
            .operation(.read)
            .guard(TestGuard())
            .operation(.create)
    }
    
    func testPrintComponent() {
        let printVisitor = PrintVisitor()
        component.visit(printVisitor)
    }
}
