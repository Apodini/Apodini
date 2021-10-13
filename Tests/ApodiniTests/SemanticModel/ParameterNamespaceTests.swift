//
// Created by Andreas Bauer on 06.01.21.
//

import XCTest
import XCTApodini
@testable import Apodini

class ParameterNamespaceTests: XCTApodiniDatabaseBirdTest {
    struct EmptyParameterNameHandler: Handler {
        @Parameter("")
        var param: String
        
        
        func handle() -> String {
            "test"
        }
    }

    struct TestHandlerPathLightweightCollision: Handler {
        @Parameter("a", .http(.path))
        var param0: String
        @Parameter("a", .http(.query))
        var param1: String
        @Parameter("b", .http(.body))
        var param2: String
        
        
        func handle() -> String {
            "test"
        }
    }
    
    struct TestHandlerLightweightContentCollision: Handler {
        @Parameter("a", .http(.path))
        var param0: String
        @Parameter("b", .http(.query))
        var param1: String
        @Parameter("b", .http(.body))
        var param2: String
        
        
        func handle() -> String {
            "test"
        }
    }
    
    struct SameNameTestHandler: Handler {
        @Parameter("a", .http(.path))
        var param0: String
        @Parameter("a", .http(.query))
        var param1: String
        @Parameter("a", .http(.body))
        var param2: String
        
        
        func handle() -> String {
            "test"
        }
    }

    func testEmptyParameterName() {
        XCTAssertRuntimeFailure(
            EmptyParameterNameHandler(),
            "You must not be able to create a Parameter instance with an empty name"
        )
    }
    
    func testIndividualParameterNamespace() throws {
        try XCTCreateMockEndpoint(TestHandlerPathLightweightCollision()).parameterNameCollisionCheck(in: .individual)
        try XCTCreateMockEndpoint(TestHandlerLightweightContentCollision()).parameterNameCollisionCheck(in: .individual)
        try XCTCreateMockEndpoint(SameNameTestHandler()).parameterNameCollisionCheck(in: .individual)
    }

    func testGlobalParameterNamespace() throws {
        XCTAssertRuntimeFailure(
            try! self.XCTCreateMockEndpoint(TestHandlerPathLightweightCollision()).parameterNameCollisionCheck(in: .global),
            "Failed to detect name collisions on .global level"
        )
        XCTAssertRuntimeFailure(
            try! self.XCTCreateMockEndpoint(TestHandlerLightweightContentCollision()).parameterNameCollisionCheck(in: .global),
            "Failed to detect name collisions on .global level"
        )
        XCTAssertRuntimeFailure(
            try! self.XCTCreateMockEndpoint(SameNameTestHandler()).parameterNameCollisionCheck(in: .global),
            "Failed to detect name collisions on .global level"
        )
    }

    func testEmptyParameterNamespace() throws {
        XCTAssertRuntimeFailure(
            try! self.XCTCreateMockEndpoint(SameNameTestHandler()).parameterNameCollisionCheck(),
            "Failed to reject empty namespace definition"
        )
    }

    func testCustomParameterPathLightweightCollisionNamespace() throws {
        let endpoint = try XCTCreateMockEndpoint(TestHandlerPathLightweightCollision())
        
        endpoint.parameterNameCollisionCheck(in: .path, .lightweight, .content)
        endpoint.parameterNameCollisionCheck(in: [.path], [.lightweight, .content])
        endpoint.parameterNameCollisionCheck(in: [.path, .content], [.lightweight])
        
        XCTAssertRuntimeFailure(
            endpoint.parameterNameCollisionCheck(in: .content, [.lightweight, .path]),
            "Failed to detect name collisions on custom level"
        )
        XCTAssertRuntimeFailure(
            endpoint.parameterNameCollisionCheck(in: [.path, .lightweight, .content], [.path, .lightweight, .content]),
            "Failed to detect name collisions on custom level"
        )
    }
    
    func testCustomParameterLightweightBodyCollisionNamespace() throws {
        let endpoint = try XCTCreateMockEndpoint(TestHandlerLightweightContentCollision())
        
        endpoint.parameterNameCollisionCheck(in: .path, .lightweight, .content)
        endpoint.parameterNameCollisionCheck(in: [.path, .lightweight], .content)
        endpoint.parameterNameCollisionCheck(in: [.path, .content], [.lightweight])
        
        XCTAssertRuntimeFailure(
            endpoint.parameterNameCollisionCheck(in: .path, [.lightweight, .content]),
            "Failed to detect name collisions on custom level"
        )
        XCTAssertRuntimeFailure(
            endpoint.parameterNameCollisionCheck(in: [.path, .lightweight, .content], [.path, .lightweight, .content]),
            "Failed to detect name collisions on custom level"
        )
    }
}
