//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import XCTest
@testable import Apodini

final class DescriptionModifierTests: ApodiniTests {
    struct TestHandler: Handler {
        func handle() -> String {
            "Hello World"
        }

        var metadata: Metadata {
            Description("The description inside the TestHandler")
        }
    }

    struct StringTestHandler: Handler {
        func handle() -> String {
            "Hello World!"
        }
    }

    struct TestComponentDescriptionMetadata: Component {
        var content: some Component {
            Group("a") {
                TestHandler()
            }
        }
    }

    struct TestComponentDescriptionModifier: Component {
        var content: some Component {
            Group("a") {
                TestHandler()
                    .description("Returns greeting with name parameter.")
            }
        }
    }
    
    struct TestComponentWithoutDescription: Component {
        var content: some Component {
            Group("a") {
                TestHandler()
            }
        }
    }

    func testEndpointDescription() throws {
        let modelBuilder = SemanticModelBuilder(app)
        let visitor = SyntaxTreeVisitor(modelBuilder: modelBuilder)
        let testComponent = TestComponentDescriptionMetadata()
        Group {
            testComponent.content
        }.accept(visitor)
        visitor.finishParsing()

        let endpoint: AnyEndpoint = try XCTUnwrap(modelBuilder.collectedEndpoints.first)
        let customDescription = endpoint[Context.self].get(valueFor: HandlerDescriptionMetadata.self)

        XCTAssertEqual(customDescription, "The description inside the TestHandler")
    }

    func testEndpointDescriptionModifier() throws {
        let modelBuilder = SemanticModelBuilder(app)
        let visitor = SyntaxTreeVisitor(modelBuilder: modelBuilder)
        let testComponent = TestComponentDescriptionModifier()
        Group {
            testComponent.content
        }.accept(visitor)
        visitor.finishParsing()

        let endpoint: AnyEndpoint = try XCTUnwrap(modelBuilder.collectedEndpoints.first)
        let customDescription = endpoint[Context.self].get(valueFor: HandlerDescriptionMetadata.self)
    
        XCTAssertEqual(customDescription, "Returns greeting with name parameter.")
    }
    
    func testEndpointDefaultDescription() throws {
        let modelBuilder = SemanticModelBuilder(app)
        let visitor = SyntaxTreeVisitor(modelBuilder: modelBuilder)
        let testComponent = TestComponentWithoutDescription()
        Group {
            testComponent.content
        }.accept(visitor)
        visitor.finishParsing()

        let endpoint: AnyEndpoint = try XCTUnwrap(modelBuilder.collectedEndpoints.first)
        
        XCTAssertEqual(endpoint.description, "TestHandler")
    }
}
