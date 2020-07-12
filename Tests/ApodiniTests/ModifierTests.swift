//
//  ModifierTests.swift
//  
//
//  Created by Paul Schmiedmayer on 6/27/20.
//

import XCTest
import NIO
import Vapor
@testable import Apodini


final class ModifierTests: XCTestCase {
    func testHTTPModifier() {
        var component: some Component {
            Group {
                Text("Post")
                    .httpMethod(.GET)
                    .httpMethod(.POST)
                Group {
                    Text("Put")
                        .httpMethod(.DELETE)
                        .httpMethod(.PUT)
                    Text("Delete")
                    Text("Post")
                        .httpMethod(.GET)
                        .httpMethod(.POST)
                }.httpMethod(.DELETE)
            }.httpMethod(.PUT)
        }
        
        let printVisitor = PrintVisitor()
        component.visit(printVisitor)
    }
    
    func testResponseModifer() {
        struct FirstTestResponseMediator: ResponseTransformer {
            func transform(response: String) -> String {
                response
            }
        }
        
        struct SecondTestResponseMediator: ResponseTransformer {
            func transform(response: String) -> String {
                response
            }
        }
        
        
        
        var component: some Component {
            Text("Hallo")
                .response(FirstTestResponseMediator())
                .response(SecondTestResponseMediator())
        }
        
        let printVisitor = PrintVisitor()
        component.visit(printVisitor)
    }
}
