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
    func testOperationModifier() {
        var component: some Component {
            Group {
                Text("Create")
                    .operation(.READ)
                    .operation(.CREATE)
                Group {
                    Text("Update")
                        .operation(.DELETE)
                        .operation(.UPDATE)
                    Text("Delete")
                    Text("Create")
                        .operation(.READ)
                        .operation(.CREATE)
                }.operation(.DELETE)
            }.operation(.UPDATE)
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
