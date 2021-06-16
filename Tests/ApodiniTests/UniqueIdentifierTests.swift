//
//  UniqueIdentifierTests.swift
//  
//
//  Created by Eldi Cano on 15.05.21.
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
        struct IdentifierAccessingExporter: StaticInterfaceExporter {
            init(_ app: Application) { }
            
            func export<H>(_ endpoint: Endpoint<H>) where H: Handler {
                _ = endpoint[AnyHandlerIdentifier.self]
            }
        }
        
        
        struct TestWebService: WebService {
            var configuration: Configuration {
                ExporterConfiguration().exporter(IdentifierAccessingExporter.self)
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
        
        XCTAssertRuntimeFailure(TestWebService.main(app: app))
    }
}
