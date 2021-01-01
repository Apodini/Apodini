//
//  ModifierTests.swift
//  
//
//  Created by Paul Schmiedmayer on 6/27/20.
//

import XCTest
import NIO
@testable import Apodini


final class ModifierTests: ApodiniTests {
    func testOperationModifier() {
        struct TestWebService: WebService {
            var content: some Component {
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
                        Text("Read")
                            .operation(.read)
                            .operation(.read)
                    }
                }
            }
        }
        
        TestWebService._main(app: app)
        #warning("Set up some expectations!")
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
        
        
        struct TestWebService: WebService {
            var content: some Component {
                Text("Hallo")
                    .response(FirstTestResponseMediator())
                    .response(SecondTestResponseMediator())
            }
        }
        
        TestWebService._main(app: app)
        #warning("Set up some expectations!")
    }
}
