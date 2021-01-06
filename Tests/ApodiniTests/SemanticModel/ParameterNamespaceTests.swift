//
// Created by Andi on 06.01.21.
//

import XCTest
@testable import Apodini

class ParameterNamespaceTests: ApodiniTests {
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

    func testIndividualParameterNamespace() {
        let handler = TestHandler()
        let endpoint = handler.mockEndpoint()

        endpoint.exportParametersMocked(namespace: .individual)
    }

    func testGlobalParameterNamespace() {
        let handler = TestHandler()
        let endpoint = handler.mockEndpoint()

        XCTAssertRuntimeFailure(
            endpoint.exportParametersMocked(namespace: .global),
            "Failed to detect name collisions on .global level"
        )
    }

    func testCustom1ParameterNamespace() {
        let handler = TestHandler()
        let endpoint = handler.mockEndpoint()

        endpoint.exportParametersMocked(namespace: [.path], [.lightweight, .content])
    }

    func testCustom2ParameterNamespace() {
        let handler = TestHandler()
        let endpoint = handler.mockEndpoint()

        endpoint.exportParametersMocked(namespace: [.lightweight], [.path, .content])
    }

    func testCustom3ParameterNamespace() {
        let handler = TestHandler()
        let endpoint = handler.mockEndpoint()


        XCTAssertRuntimeFailure(
            endpoint.exportParametersMocked(namespace: [.content], [.lightweight, .path]),
            "Failed to detect name collisions on custom level"
        )
    }
}
