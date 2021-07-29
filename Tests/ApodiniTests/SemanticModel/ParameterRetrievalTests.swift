//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
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
        var prefix: String? = "Standard Prefix" // "explicit nil" is supplied => defaultValue is overwritten


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
