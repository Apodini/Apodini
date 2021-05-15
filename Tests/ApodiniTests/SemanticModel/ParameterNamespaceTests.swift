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

    struct TestHandler: Handler {
        @Parameter("a", .http(.path))
        var param0: String
        @Parameter("a", .http(.query))
        var param1: String
        @Parameter("b", .http(.body))
        var param2: String
        @Parameter("b", .http(.header))
        var param3: String

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
        @Parameter("a", .http(.header))
        var param3: String

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
        handler.oldMockEndpoint().parameterNameCollisionCheck(in: namespaces)
    }

    func testIndividualParameterNamespace() {
        parameterNameCollisionCheck(
            on: TestHandler(),
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
                on: TestHandler(),
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

    func testEmptyParameterNamespace() throws {
        XCTAssertRuntimeFailure(
            TestHandler().oldMockEndpoint().parameterNameCollisionCheck(),
            "Failed to reject empty namespace definition"
        )
    }

    func testCustom1ParameterNamespace() throws {
        let endpoint = try TestHandler().mockEndpoint(application: app)

        endpoint.parameterNameCollisionCheck(in: .path, [.lightweight, .content])
    }

    func testCustom2ParameterNamespace() throws {
        let endpoint = try TestHandler().mockEndpoint(application: app)

        endpoint.parameterNameCollisionCheck(in: .lightweight, [.path, .content])
    }

    func testCustom3ParameterNamespace() throws {
        let endpoint = try TestHandler().mockEndpoint(application: app)

        endpoint.parameterNameCollisionCheck(in: .path, .lightweight, .content, .header)
        endpoint.parameterNameCollisionCheck(in: [.path, .header], [.lightweight, .content])
        endpoint.parameterNameCollisionCheck(in: [.path, .content], [.lightweight, .header])
        XCTAssertRuntimeFailure(
            endpoint.parameterNameCollisionCheck(in: .content, [.lightweight, .path], .header),
            "Failed to detect name collisions on custom level"
        )
        XCTAssertRuntimeFailure(
            endpoint.parameterNameCollisionCheck(in: .path, [.content, .header], .lightweight),
            "Failed to detect name collisions on custom level"
        )
        XCTAssertRuntimeFailure(
            endpoint.parameterNameCollisionCheck(in: [.path, .lightweight], [.content, .header]),
            "Failed to detect name collisions on custom level"
        )
        XCTAssertRuntimeFailure(
            endpoint.parameterNameCollisionCheck(in: [.path, .lightweight, .content, .header], [.path, .lightweight, .content, .header]),
            "Failed to detect name collisions on custom level"
        )
    }
}
