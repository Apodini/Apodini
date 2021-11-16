//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import XCTest
@testable import Apodini
@testable import ApodiniOpenAPI


final class TagMetadataTests: ApodiniTests {
    struct TestHandler: Handler {
        @Binding
        var name: String

        func handle() -> String {
            "Hello \(name)"
        }

        var metadata: Metadata {
            Tags("tag1")
        }
    }

    struct TestComponentTag: Component {
        @PathParameter
        var name: String

        var content: some Component {
            Group("register", $name) {
                TestHandler(name: $name)
                    .tags("People_Register")
            }.tags("tag3")
        }
    }

    func testEndpointTag() throws {
        let modelBuilder = SemanticModelBuilder(app)
        let visitor = SyntaxTreeVisitor(modelBuilder: modelBuilder)
        let testComponent = TestComponentTag()
        Group {
            testComponent.content
        }.accept(visitor)
        visitor.finishParsing()

        let endpoint: AnyEndpoint = try XCTUnwrap(modelBuilder.collectedEndpoints.first)
        let tags = endpoint[Context.self].get(valueFor: TagContextKey.self)
    
        XCTAssertEqual(tags, ["tag3", "tag1", "People_Register"])
    }
}
