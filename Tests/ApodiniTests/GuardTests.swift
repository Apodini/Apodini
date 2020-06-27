//
//  GuardTests.swift
//  
//
//  Created by Paul Schmiedmayer on 6/27/20.
//

import XCTest
import NIO
@testable import Apodini


final class GuardTests: XCTestCase {
    struct TestGuard: Guard {
        func check(_ request: Request) -> EventLoopFuture<Void> {
            print("Execute Guard")
            return request.eventLoop.makeSucceededFuture(Void())
        }
    }
    
    
    var component: some Component {
        Text("Hallo")
            .httpType(.get)
            .guard(TestGuard())
            .httpType(.post)
    }
    
    func testPrintComponent() {
        var printVisitor = PrintVisitor()
        component.visit(&printVisitor)
    }
}

