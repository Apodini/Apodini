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
        struct FirstTestResponseMediator: Codable, Content, ResponseMediator {
            let text: String
            
            init(_ response: String) {
                text = response
            }
        }
        
        struct SecondTestResponseMediator: Codable, Content, ResponseMediator {
            let text: String
            
            init(_ response: FirstTestResponseMediator) {
                text = response.text
            }
        }
        
        
        
        var component: some Component {
            Text("Hallo")
                .response(FirstTestResponseMediator.self)
                .response(SecondTestResponseMediator.self)
        }
        
        let printVisitor = PrintVisitor()
        component.visit(printVisitor)
    }
}
