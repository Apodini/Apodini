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
        var request: Apodini.Request
        
        func check() {
            if let request = request as? Vapor.Request {
                request.logger.info("Execute Guard")
            }
        }
    }
    
    
    var component: some Component {
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
