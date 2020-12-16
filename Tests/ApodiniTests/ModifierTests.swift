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
        var component: some EndpointProvidingNode {
            Group {
                Text("Create")
                    .operation(.read)
                    .operation(.create)
                Group {
                    Text("Update")
                        .operation(.delete)
                        .operation(.update)
                    Text("Delete")
                        .operation(.delete)
                    Text("Create")
                        .operation(.read)
                        .operation(.create)
                }
            }
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
        
        
        @EndpointProvidingNodeBuilder
        var component: some EndpointProvidingNode {
            Text("Hallo")
                .response(FirstTestResponseMediator())
                .response(SecondTestResponseMediator())
        }
        
        let printVisitor = PrintVisitor()
        component.visit(printVisitor)
    }
}
