//
//  EndpointsTreeTests.swift
//  
//
//  Created by Lorena Schlesinger on 06.12.20.
//

@testable import Apodini
import XCTest


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
        @Parameter(.http(.path))
        var name: String
        var nameParameter: Parameter<String> {
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

    struct TestHandler2: Handler {
        @Parameter(.http(.path))
        var secondName: String
        var nameParameter: Parameter<String> {
            _secondName
        }

        func handle() -> String {
            "Hello \(secondName)"
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

        let parameters: [AnyEndpointParameter] = endpoint.parameters
        let nameParameter = parameters.first { $0.label == "_name" }!
        let timesParameter = parameters.first { $0.label == "_times" }!
        let birthdateParameter = parameters.first { $0.label == "_birthdate" }!

        // check that the _ is correctly removed on name and any manual name is properly set
        XCTAssertEqual(nameParameter.name, "name")
        XCTAssertEqual(timesParameter.name, "multiply")
        XCTAssertEqual(birthdateParameter.name, "birthdate")
        
        // basic checks to ensure proper parameter parsing
        XCTAssertEqual(nameParameter.id, testHandler.nameParameter.id)
        XCTAssertEqual(timesParameter.id, testHandler.timesParameter.id)
        XCTAssertEqual(timesParameter.options.option(for: PropertyOptionKey.http), testHandler.timesParameter.option(for: PropertyOptionKey.http))
        XCTAssertEqual(birthdateParameter.id, testHandler.birthdateParameter.id)
        
        // check whether categorization works
        XCTAssertEqual(birthdateParameter.kind, .content)
        XCTAssertEqual(timesParameter.kind, .lightweight)
        XCTAssertEqual(nameParameter.kind, .path)

        // check necessity
        XCTAssertEqual(birthdateParameter.necessity, .required)
        XCTAssertEqual(timesParameter.necessity, .optional)
        XCTAssertEqual(nameParameter.necessity, .required)

        // check default value
        XCTAssertNil(birthdateParameter.typeErasuredDefaultValue)
        // swiftlint:disable:next force_cast
        XCTAssertEqual(timesParameter.typeErasuredDefaultValue as! Int?, 1)
        XCTAssertNil(nameParameter.typeErasuredDefaultValue)
    }

    func testOverwriteEndpoint() throws {
        let endpointTreeNode = EndpointsTreeNode(path: RootPath())
        let comp = TestHandler()
        var endpoint1 = comp.mockEndpoint()
        endpointTreeNode.addEndpoint(&endpoint1, at: ["test"])

        XCTAssertRuntimeFailure(endpointTreeNode.addEndpoint(&endpoint1, at: ["test"]))
    }

    func testAddEndpointWithWrongParameterKind() throws {
        let endpointTreeNode = EndpointsTreeNode(path: RootPath())
        let param = Parameter<String>(.http(.query))
        let comp = TestHandler(name: param)
        var endpoint1 = comp.mockEndpoint()

        XCTAssertRuntimeFailure(endpointTreeNode.addEndpoint(&endpoint1, at: ["test", param]))
    }

    func testAddEndpointWithPathCollision() throws {
        let endpointTreeNode = EndpointsTreeNode(path: RootPath())
        let param1 = Parameter<String>(from: UUID())
        let comp = TestHandler(name: param1)
        let param2 = Parameter<String>(from: UUID())
        let comp2 = TestHandler2(secondName: param2)
        var endpoint1 = comp.mockEndpoint()
        var endpoint2 = comp2.mockEndpoint()
        endpointTreeNode.addEndpoint(&endpoint1, at: ["test", param1])

        XCTAssertRuntimeFailure(endpointTreeNode.addEndpoint(&endpoint2, at: ["test", param2]))
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
        var context = endpoint.createConnectionContext(for: exporter)

        // handle a request (The actual request is unused in the MockExporter)
        let response = try context.handle(request: "Example Request", eventLoop: app.eventLoopGroup.next())
                .wait()
        guard case let .final(responseValue) = response.typed(String.self) else {
            XCTFail("Expected return value to be wrapped in Response.final by default")
            return
        }
        
        XCTAssertEqual(responseValue, "✅ Hello \(name) ✅")
    }
}
