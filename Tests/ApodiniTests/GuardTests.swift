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
        @Apodini.Request
        var request: Vapor.Request
        
        func check() {
            request.logger.info("Execute Guard")
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

