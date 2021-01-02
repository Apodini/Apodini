//
// Created by Andi on 25.12.20.
//

import XCTest
@testable import Apodini

class ParameterRetrievalTests: ApodiniTests {
    struct TestHandler: Handler {
        @Parameter
        var name: String // will be set to "Rudi"
        @Parameter
        var times: Int? // will be set to 3
        @Parameter
        var separator: String = " " // no value (nil) is supplied => defaultValue is used
        @Parameter
        var prefix: String? = "Standard Prefix" // "explicit nil" (.null) is supplied => defaultValue is overwritten


        func handle() -> String {
            (prefix ?? "") + (1...(times ?? 1))
                    .map { _ in
                        "Hello \(name)!"
                    }
                    .joined(separator: separator)
        }
    }

    func testParameterRetrieval() throws {
        let handler = TestHandler()
        let endpoint = handler.mockEndpoint()

        let exporter = MockExporter<String>(queued: "Rudi", 3, nil, .null)

        let requestHandler = endpoint.createRequestHandler(for: exporter)
        let result = try requestHandler(request: "Example Request", eventLoop: app.eventLoopGroup.next())
                .wait()
        guard case let .final(responseValue) = result else {
            XCTFail("Expected return value to be wrapped in Action.final by default")
            return
        }
        let stringResult: String = try XCTUnwrap(responseValue.value as? String)

        XCTAssertEqual(stringResult, "Hello Rudi! Hello Rudi! Hello Rudi!")
    }
}
