//
// Created by Andreas Bauer on 25.12.20.
//

@testable import Apodini
import XCTApodini


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

        let exporter = MockExporter<String>(queued: "Rudi", 3, nil, .some(.none))

        let context = endpoint.createConnectionContext(for: exporter)
        
        try XCTCheckResponse(
            context.handle(request: "Example Request", eventLoop: app.eventLoopGroup.next()),
            content: "Hello Rudi! Hello Rudi! Hello Rudi!",
            connectionEffect: .close
        )
    }
}
