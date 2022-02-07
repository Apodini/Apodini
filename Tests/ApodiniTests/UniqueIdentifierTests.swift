//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import XCTest
@testable import Apodini
import XCTApodini

final class UniqueIdentifierTests: ApodiniTests {
    private static let first = AnyHandlerIdentifier("first")
    private static let second = AnyHandlerIdentifier("second")
    
    struct SomeIdentifiableHandler: IdentifiableHandler {
        var handlerId = UniqueIdentifierTests.first
        
        func handle() throws -> String {
            ""
        }
    }
    
    func testUniqueIdentifiers() {
        struct IdentifierAccessing: Configuration {
            func configure(_ app: Apodini.Application) {
                let identifierExporter = IdentifierAccessingExporter(app)
                app.registerExporter(exporter: identifierExporter)
            }
        }
        
        struct IdentifierAccessingExporter: InterfaceExporter {
            init(_ app: Application) { }
            
            func export<H>(_ endpoint: Endpoint<H>) where H: Handler {
                _ = endpoint[AnyHandlerIdentifier.self]
            }
            
            func export<H>(blob endpoint: Endpoint<H>) where H: Handler, H.Response.Content == Blob {
                export(endpoint)
            }
        }
        
        
        struct TestWebService: WebService {
            var configuration: Configuration {
                IdentifierAccessing()
            }
            
            var content: some Component {
                Group("ok") {
                    SomeIdentifiableHandler()
                        .identified(by: UniqueIdentifierTests.first)
                }
                Group("fail") {
                    SomeIdentifiableHandler()
                        .identified(by: UniqueIdentifierTests.second)
                }
            }
        }
        
        weak var weakApp = app
        
        guard let app = weakApp else {
            return XCTFail("App deallocated")
        }
        
        XCTAssertRuntimeFailure(try TestWebService().start(app: app))
    }
}
