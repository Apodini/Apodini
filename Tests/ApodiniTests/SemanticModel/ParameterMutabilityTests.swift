//
//  ParameterMutabilityTests.swift
//  
//
//  Created by Max Obermeier on 04.01.21.
//

import XCTest
@testable import Apodini

class ParameterMutabilityTests: ApodiniTests {
    struct TestHandler: Handler {
        // variable
        @Parameter
        var name: String
        // constant
        @Parameter(.mutability(.constant))
        var times: Int
        // constant with default value
        @Parameter(.mutability(.constant))
        var separator: String = " "

        func handle() -> String {
            (1...times)
                    .map { _ in
                        "Hello \(name)!"
                    }
                    .joined(separator: separator)
        }
    }

    func testVariableCanBeChanged() throws {
        let handler = TestHandler()
        let endpoint = handler.mockEndpoint()

        let exporter = MockExporter<String>(queued: "Rudi", 3, ", ", "Peter", 3, ", ")

        var context = endpoint.createConnectionContext(for: exporter)
        
        // both calls should succeed
        _ = try context.handle(request: "Example Request", eventLoop: app.eventLoopGroup.next())
                .wait()
        _ = try context.handle(request: "Example Request", eventLoop: app.eventLoopGroup.next())
                .wait()
    }
    
    func testConstantCannotBeChanged() throws {
        let handler = TestHandler()
        let endpoint = handler.mockEndpoint()

        let exporter = MockExporter<String>(queued: "Rudi", 3, ", ", "Rudi", 4, ", ")

        var context = endpoint.createConnectionContext(for: exporter)
        
        // second call should fail
        _ = try context.handle(request: "Example Request", eventLoop: app.eventLoopGroup.next())
                .wait()
        do {
            _ = try context.handle(request: "Example Request", eventLoop: app.eventLoopGroup.next())
                    .wait()
            XCTFail("Validation should fail, constant was changed!")
        } catch {}
    }
    
    func testConstantWithDefaultCannotBeChanged() throws {
        let handler = TestHandler()
        let endpoint = handler.mockEndpoint()

        let exporter = MockExporter<String>(queued: "Rudi", 3, nil, "Rudi", 4, ", ")

        var context = endpoint.createConnectionContext(for: exporter)
        
        // second call should fail
        _ = try context.handle(request: "Example Request", eventLoop: app.eventLoopGroup.next())
                .wait()
        do {
            _ = try context.handle(request: "Example Request", eventLoop: app.eventLoopGroup.next())
                    .wait()
            XCTFail("Validation should fail, constant was changed!")
        } catch {}
    }
}
