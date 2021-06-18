//
// Created by Andreas Bauer on 06.01.21.
//

import XCTest
import XCTApodini
@testable import Apodini

class ParameterNamespaceTests: ApodiniTests {
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
    
    private func parameterNameCollisionCheck<H: Handler>(on handler: H, in namespaces: [ParameterNamespace]) {
        handler.mockEndpoint().parameterNameCollisionCheck(in: namespaces)
    }

    func testIndividualParameterNamespace() {
        parameterNameCollisionCheck(
            on: TestHandlerPathLightweightCollision(),
            in: .individual
        )
        
        parameterNameCollisionCheck(
            on: TestHandlerLightweightContentCollision(),
            in: .individual
        )
        
        parameterNameCollisionCheck(
            on: SameNameTestHandler(),
            in: .individual
        )
    }

    func testGlobalParameterNamespace() {
        XCTAssertRuntimeFailure(
            self.parameterNameCollisionCheck(
                on: TestHandlerPathLightweightCollision(),
                in: .global
            ),
            "Failed to detect name collisions on .global level"
        )
        
        XCTAssertRuntimeFailure(
            self.parameterNameCollisionCheck(
                on: TestHandlerLightweightContentCollision(),
                in: .global
            ),
            "Failed to detect name collisions on .global level"
        )
        
        XCTAssertRuntimeFailure(
            self.parameterNameCollisionCheck(
                on: SameNameTestHandler(),
                in: .global
            ),
            "Failed to detect name collisions on .global level"
        )
    }

    func testEmptyParameterNamespace() {
        XCTAssertRuntimeFailure(
            SameNameTestHandler().mockEndpoint().parameterNameCollisionCheck(),
            "Failed to reject empty namespace definition"
        )
    }

    func testCustomParameterPathLightweightCollisionNamespace() {
        let handler = TestHandlerPathLightweightCollision()
        let endpoint = handler.mockEndpoint()

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
    
    func testCustomParameterLightweightBodyCollisionNamespace() {
        let handler = TestHandlerLightweightContentCollision()
        let endpoint = handler.mockEndpoint()

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
