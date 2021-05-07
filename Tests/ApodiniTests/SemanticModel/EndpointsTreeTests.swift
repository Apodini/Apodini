//
//  EndpointsTreeTests.swift
//
//
//  Created by Lorena Schlesinger on 06.12.20.
//

@testable import Apodini
import Foundation
import XCTest
import XCTApodini


final class EndpointsTreeTests: ApodiniTests {
    struct Birthdate: Codable {
        let year: Int
        let day: Int
        let month: Int
    }

    struct BasicTestHandler: Handler {
        @Parameter
        var name: String

        func handle() -> String {
            "Hello \(name)"
        }
    }
    
    struct TestHandler: Handler {
        @Binding
        var name: String
        var nameBinding: Binding<String> {
            _name
        }

        @Parameter("multiply")
        var times: Int? = 1
        var timesParameter: Parameter<Int?> {
            _times
        }

        @Parameter
        var birthdate: Birthdate
        var birthdateParameter: Parameter<Birthdate> {
            _birthdate
        }
        
        func handle() -> String {
            // swiftlint:disable:next force_unwrapping
            (0...times!)
                .map { _ in
                    "Hello \(name) born in \(birthdate.year)!"
                }
                .joined(separator: " ")
        }
    }
    
    struct TestComponent: Component {
        @PathParameter
        var name: String
        
        var content: some Component {
            Group("birthdate", $name) {
                TestHandler(name: $name)
            }
        }
    }
    
    func testEndpointParameters() throws {
        let testComponent = TestComponent()
        let testHandler: TestHandler = try XCTUnwrap(testComponent.content.content as? TestHandler)
        let endpoint = testHandler.mockEndpoint()

        let parameters = endpoint.parameters
        let nameParameter = parameters.first { $0.label == "_name" }!
        let timesParameter = parameters.first { $0.label == "_times" }!
        let birthdateParameter = parameters.first { $0.label == "_birthdate" }!

        // check that the _ is correctly removed on name and any manual name is properly set
        XCTAssertEqual(nameParameter.name, "name")
        XCTAssertEqual(timesParameter.name, "multiply")
        XCTAssertEqual(birthdateParameter.name, "birthdate")

        // basic checks to ensure proper parameter parsing
        XCTAssertEqual(nameParameter.id, testHandler.nameBinding.parameterId)
        XCTAssertEqual(timesParameter.id, testHandler.timesParameter.id)
        XCTAssertEqual(timesParameter.option(for: PropertyOptionKey.http), testHandler.timesParameter.option(for: PropertyOptionKey.http))
        XCTAssertEqual(birthdateParameter.id, testHandler.birthdateParameter.id)

        // check whether categorization works
        XCTAssertEqual(birthdateParameter.parameterType, .content)
        XCTAssertEqual(timesParameter.parameterType, .lightweight)
        XCTAssertEqual(nameParameter.parameterType, .path)

        // check necessity
        XCTAssertEqual(birthdateParameter.necessity, .required)
        XCTAssertEqual(timesParameter.necessity, .optional)
        XCTAssertEqual(nameParameter.necessity, .required)

        // check default value
        XCTAssertNil(birthdateParameter.typeErasuredDefaultValue?())
        // swiftlint:disable:next force_cast
        XCTAssertEqual(timesParameter.typeErasuredDefaultValue?() as! Int?, 1)
        XCTAssertNil(nameParameter.typeErasuredDefaultValue?())
    }

    func testRequestHandler() throws {
        let name = "Paul" // this is the parameter value we want to inject

        // setting up a exporter
        let exporter = MockExporter<String>(queued: name)

        // creating handlers, guards and transformers
        let handler = BasicTestHandler()
        let transformer = EmojiMediator(emojis: "✅")
        let printGuard = AnyGuard(PrintGuard())

        // creating a endpoint model from the handler
        let endpoint = handler.mockEndpoint(guards: [ { printGuard } ], responseTransformers: [ { transformer } ])

        // creating a context for the exporter
        let context = endpoint.createConnectionContext(for: exporter)

        // handle a request (The actual request is unused in the MockExporter)
        try XCTCheckResponse(
            context.handle(request: "Example Request", eventLoop: app.eventLoopGroup.next()),
            content: "✅ Hello \(name) ✅",
            connectionEffect: .close
        )
    }
    
    func testEndpointPathEquatable() throws {
        let path1: EndpointPath = .root
        let path2: EndpointPath = .string("a")
        let path3: EndpointPath = .parameter(EndpointPathParameter<String>(id: UUID()))
        
        XCTAssertEqual(path1, path1)
        XCTAssertEqual(path2, path2)
        XCTAssertEqual(path3, path3)
        XCTAssertNotEqual(path1, path2)
        XCTAssertNotEqual(path2, path3)
        XCTAssertNotEqual(path1, path3)
    }


    struct HandlerMissingPathParameter: Handler {
        func handle() -> String {
            "Hello World"
        }
    }

    @PathParameter
    var testParameter: String

    @ComponentBuilder
    var missingPathParameterWebService: some Component {
        Group("test", $testParameter) {
            HandlerMissingPathParameter()
        }
    }

    func testRuntimeErrorOnMissingPathParameterDeclaration() {
        let builder = SemanticModelBuilder(app)
        let visitor = SyntaxTreeVisitor(modelBuilder: builder)
        self.missingPathParameterWebService.accept(visitor)
        XCTAssertRuntimeFailure(
            builder.finishedRegistration(),
            "Parsing a Handler with missing PathParameter declaration should fail!"
        )
    }
}
