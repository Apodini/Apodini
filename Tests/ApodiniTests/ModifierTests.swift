//
//  ModifierTests.swift
//  
//
//  Created by Paul Schmiedmayer on 6/27/20.
//

import XCTest
import NIO
@testable import Apodini


final class ModifierTests: XCTestCase {
    func testHTTPModifier() {
        var component: some Component {
            Group {
                Text("Post")
                    .httpType(.get)
                    .httpType(.post)
                Group {
                    Text("Put")
                        .httpType(.delete)
                        .httpType(.put)
                    Text("Delete")
                    Text("Post")
                        .httpType(.get)
                        .httpType(.post)
                }.httpType(.delete)
            }.httpType(.put)
        }
        
        var printVisitor = PrintVisitor()
        component.visit(&printVisitor)
    }
    
    func testResponseModifer() {
        struct FirstTestResponseMediator: ResponseMediator {
            let text: String
            
            init(_ response: String) {
                text = response
            }
        }
        
        struct SecondTestResponseMediator: ResponseMediator {
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
        
        var printVisitor = PrintVisitor()
        component.visit(&printVisitor)
    }
}
