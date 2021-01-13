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
    
    class StringClass: Codable {
        var string: String
        
        init(string: String) {
            self.string = string
        }
    }
    
    struct TestHandlerUsingClassType: Handler {
        @Parameter
        var name: StringClass = StringClass(string: "Apodini")
        
        @Parameter
        var override: Bool = false
        
        func handle() -> String {
            if override {
                self.name.string = "NotApodini"
            }
            return name.string
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
    
    func testMutationOnClassTypeDefaultParameterIsNotShared() throws {
        let handler = TestHandlerUsingClassType()
        let endpoint = handler.mockEndpoint()

        let exporter1 = MockExporter<String>(queued: nil, true)
        let exporter2 = MockExporter<String>(queued: nil)

        var context1 = endpoint.createConnectionContext(for: exporter1)
        var context2 = endpoint.createConnectionContext(for: exporter2)
        
        // second call should still return "Apodini"
        _ = try context1.handle(request: "Example Request", eventLoop: app.eventLoopGroup.next())
                .wait()
        
        let response = try context2.handle(request: "Example Request", eventLoop: app.eventLoopGroup.next())
                .wait()
        
        switch response.typed(String.self) {
        case .some(.final("Apodini")):
            break
        default:
            XCTFail()
        }
    }
}
