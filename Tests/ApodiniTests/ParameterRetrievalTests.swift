//
// Created by Andi on 25.12.20.
//

import XCTest
@testable import Apodini

class ParameterRetrievalTests: ApodiniTests {
    struct TestHandler: Component {
        @Parameter
        var name: String
        @Parameter
        var times: Int?
        @Parameter
        var separator: String? = " "
        @Parameter
        var prefix: String?


        func handle() -> String {
            (prefix ?? "") + (1...(times ?? 1))
                    .map { _ in
                        "Hello \(name)!"
                    }
                    // swiftlint:disable:next force_unwrapping
                    .joined(separator: separator!)
        }
    }

    func testParameterRetrieval() throws {
        let handler = TestHandler()
        let endpoint = handler.mockEndpoint()

        let exporter = MockExporter<String>(queued: "Rudi", 3, nil, nil)

        let requestHandler = endpoint.createRequestHandler(for: exporter)
        let result = try requestHandler
                .handleRequest(request: "Example Request", eventLoop: app.eventLoopGroup.next())
                .wait()
        let stringResult: String = try XCTUnwrap(result as? String)

        XCTAssertEqual(stringResult, "Hello Rudi! Hello Rudi! Hello Rudi!")
    }
}
