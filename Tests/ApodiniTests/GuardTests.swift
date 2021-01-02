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
            // To Do: fix this
            print("Execute Guard for \(request)")
        }
    }
    
    
    var component: some Handler {
        Text("Hallo")
            .operation(.read)
            .guard(TestGuard())
            .operation(.create)
    }
    
    func testPrintComponent() {
        let printVisitor = PrintVisitor()
        component.accept(printVisitor)
    }
}
