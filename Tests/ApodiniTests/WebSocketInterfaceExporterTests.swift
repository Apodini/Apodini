//
//  WebSocketInterfaceExporterTests.swift
//  
//
//  Created by Max Obermeier on 03.01.21.
//

import XCTest
import WebSocketInfrastructure
@testable import Apodini

class WebSocketInterfaceExporterTests: ApodiniTests {
    struct Parameters: Apodini.Content {
        var param0: String
        var param1: String?
        var pathA: String
        var pathB: String?
        var bird: Bird
    }

    struct ParameterRetrievalTestHandler: Handler {
        @Parameter
        var param0: String
        @Parameter
        var param1: String?

        @Parameter(.http(.path))
        var pathA: String
        var pathAParameter: Parameter<String> {
            _pathA
        }

        @Parameter(.http(.path))
        var pathB: String?
        var pathBParameter: Parameter<String?> {
            _pathB
        }

        @Parameter
        var bird: Bird


        func handle() -> Parameters {
            Parameters(param0: param0, param1: param1, pathA: pathA, pathB: pathB, bird: bird)
        }
    }

    struct User: Apodini.Content, Identifiable, Decodable {
        let id: String
        let name: String
    }
    
    struct DecodedResponseContainer<Data: Decodable>: Decodable {
        var content: Data
    }

    struct UserHandler: Handler {
        @Parameter
        var userId: User.ID
        @Parameter
        var name: String

        func handle() -> User {
            User(id: userId, name: name)
        }
    }
    
    struct StatefulUserHandler: Handler {
        @Parameter(.mutability(.constant))
        var userId: User.ID
        @Parameter
        var name: String?
        @Apodini.Environment(\.connection)
        var connection: Connection

        func handle() -> Apodini.Response<User> {
            if connection.state == .end {
                XCTAssertNotNil(name)
                // swiftlint:disable:next force_unwrapping
                return .final(User(id: userId, name: name!))
            } else {
                return .nothing
            }
        }
    }
    
    struct ThrowingHandlerNoImpact: Handler {
        @Throws(.other, .webSocketConnectionConsequence(.none)) var error: ApodiniError
        @Parameter var doThrow: Bool = true
        
        func handle() throws -> some ResponseTransformable {
            if doThrow {
                throw error
            } else {
                return true
            }
        }
    }
    
    struct ThrowingHandlerCloseContext: Handler {
        @Throws(.other, .webSocketConnectionConsequence(.closeContext)) var error: ApodiniError
        @Parameter var doThrow: Bool = true
        
        func handle() throws -> some ResponseTransformable {
            if doThrow {
                throw error
            } else {
                return true
            }
        }
    }
    
    struct ThrowingHandlerCloseChannel: Handler {
        @Throws(.other, .webSocketConnectionConsequence(.closeChannel)) var error: ApodiniError
        @Parameter var doThrow: Bool = true
        
        func handle() throws -> some ResponseTransformable {
            if doThrow {
                throw error
            } else {
                return true
            }
        }
    }

    @PathParameter
    var userId: User.ID

    @ComponentBuilder
    var testService: some Component {
        Group("user", $userId) {
            UserHandler(userId: $userId)
            Group("stream") {
                StatefulUserHandler(userId: $userId)
            }
        }
        Group("throwing") {
            Group("none") {
                ThrowingHandlerNoImpact()
            }
            Group("context") {
                ThrowingHandlerCloseContext()
            }
            Group("channel") {
                ThrowingHandlerCloseChannel()
            }
        }
    }

    func testParameterRetrieval() throws {
        let handler = ParameterRetrievalTestHandler()
        let endpoint = handler.mockEndpoint()

        let exporter = WebSocketInterfaceExporter(app)
        var context = endpoint.createConnectionContext(for: exporter)

        let bird = Bird(name: "Rudi", age: 12)

        var input = SomeInput(parameters: [
            "bird": BasicInputParameter<Bird>(),
            "a": BasicInputParameter<UUID>(),
            "param0": BasicInputParameter<String>(),
            "pathA": BasicInputParameter<String>()
        ])
        
        _ = input.update("bird", using: bird.mockDecoder())
        _ = input.update("a", using: handler.pathAParameter.id.mockDecoder())
        _ = input.update("param0", using: "value0".mockDecoder())
        _ = input.update("pathA", using: "a".mockDecoder())
        
        _ = input.check()
        input.apply()
        
        print(input.parameters)

        let result = try context.handle(request: input, eventLoop: app.eventLoopGroup.next())
                .wait()
        guard case let .final(responseValue) = result.typed(Parameters.self) else {
            XCTFail("Expected return value to be wrapped in Response.automatic by default")
            return
        }

        XCTAssertEqual(responseValue.param0, "value0")
        XCTAssertEqual(responseValue.param1, nil)
        XCTAssertEqual(responseValue.pathA, "a")
        XCTAssertEqual(responseValue.pathB, nil)
        XCTAssertEqual(responseValue.bird, bird)
    }

    func testWebSocketConnectionRequestResponseSchema() throws {
        let builder = SharedSemanticModelBuilder(app)
            .with(exporter: WebSocketInterfaceExporter.self)
        let visitor = SyntaxTreeVisitor(semanticModelBuilders: [builder])
        testService.accept(visitor)
        visitor.finishParsing()

        try app.start()
        
        let client = StatelessClient(on: app.eventLoopGroup.next())
        
        
        let userId = "1234"
        let name = "Rudi"

        struct UserHandlerInput: Encodable {
            let userId: String
            let name: String
        }
        
        let user: User = try client.resolve(one: UserHandlerInput(userId: userId, name: name), on: "user.:userId:").wait()
        
        XCTAssertEqual(user.id, userId)
        XCTAssertEqual(user.name, name)
    }
    
    func testWebSocketConnectionClientStreamSchema() throws {
        let builder = SharedSemanticModelBuilder(app)
            .with(exporter: WebSocketInterfaceExporter.self)
        let visitor = SyntaxTreeVisitor(semanticModelBuilders: [builder])
        testService.accept(visitor)
        visitor.finishParsing()

        try app.start()
        
        let client = StatelessClient(on: app.eventLoopGroup.next())
        
        
        let userId = "1234"
        let name = "Rudi"
        
        struct UserHandlerInput: Encodable {
            let userId: String
            let name: String?
        }
        
        // We test here that the input is aggregated correctly. We expect
        // both parameters to be defined in the end. JSONEncoder does not
        // encode an explicit `null` for empty optionals. Thus the third
        // message does not reset `name` to `nil`.
        
        let user: [User] = try client.resolve(
            UserHandlerInput(userId: userId, name: nil),
            UserHandlerInput(userId: userId, name: name),
            UserHandlerInput(userId: userId, name: nil),
            on: "user.:userId:.stream")
        .wait()
        
        XCTAssertEqual(user.count, 1)
        
        if let first = user.first {
            XCTAssertEqual(first.id, userId)
            
            XCTAssertEqual(first.name, name)
        }
    }
    
    func testWebSocketBadTypeError() throws {
        let builder = SharedSemanticModelBuilder(app)
            .with(exporter: WebSocketInterfaceExporter.self)
        let visitor = SyntaxTreeVisitor(semanticModelBuilders: [builder])
        testService.accept(visitor)
        visitor.finishParsing()

        try app.start()
        
        let client = StatelessClient(on: app.eventLoopGroup.next())
        
        
        let userId = 1234
        let name = "Rudi"

        struct UserHandlerInput: Encodable {
            let userId: Int
            let name: String
        }
        
        do {
            let user: User = try client.resolve(one: UserHandlerInput(userId: userId, name: name), on: "user.:userId:").wait()
            _ = user
            XCTFail("Call should have failed as the userId was provided as int and not string.")
        } catch { }
    }
    
    func testWebSocketThrowingNoInmpact() throws {
        let builder = SharedSemanticModelBuilder(app)
            .with(exporter: WebSocketInterfaceExporter.self)
        let visitor = SyntaxTreeVisitor(semanticModelBuilders: [builder])
        testService.accept(visitor)
        visitor.finishParsing()

        try app.start()
        
        let client = StatelessClient(on: app.eventLoopGroup.next(), ignoreErrors: true)
        
        let output: [Bool] = try client.resolve(
            true.asInputForThrowingHandler,
            false.asInputForThrowingHandler,
            on: "throwing.none")
            .wait()
        XCTAssertEqual(output, [true])
    }
    
    func testWebSocketThrowingCloseContext() throws {
        let builder = SharedSemanticModelBuilder(app)
            .with(exporter: WebSocketInterfaceExporter.self)
        let visitor = SyntaxTreeVisitor(semanticModelBuilders: [builder])
        testService.accept(visitor)
        visitor.finishParsing()

        try app.start()
        
        let client = StatelessClient(on: app.eventLoopGroup.next(), ignoreErrors: true)
        
        let output: [Bool] = try client.resolve(
            true.asInputForThrowingHandler,
            false.asInputForThrowingHandler,
            on: "throwing.context")
            .wait()
        XCTAssertEqual(output, [])
    }
    
    func testWebSocketThrowingCloseChannel() throws {
        let builder = SharedSemanticModelBuilder(app)
            .with(exporter: WebSocketInterfaceExporter.self)
        let visitor = SyntaxTreeVisitor(semanticModelBuilders: [builder])
        testService.accept(visitor)
        visitor.finishParsing()

        try app.start()
        
        let client = StatelessClient(on: app.eventLoopGroup.next(), ignoreErrors: true)
        
        do {
            let output: [Bool] = try client.resolve(
                true.asInputForThrowingHandler,
                false.asInputForThrowingHandler,
                on: "throwing.channel")
                .wait()
            _ = output
            XCTFail("Expected WebSocket to close early and thus client to throw an error.")
        } catch { }
    }
}

private struct MockParameterDecoder<Type>: ParameterDecoder {
    let value: Type??
    
    func decode<T>(_: T.Type) throws -> T?? where T: Decodable {
        if let typedValue = value as? T?? {
            return typedValue
        }
        return nil
    }
}

private extension Decodable {
    func mockDecoder() -> MockParameterDecoder<Self> {
        MockParameterDecoder(value: self)
    }
}

private struct ThrowingHandlerInput: Encodable {
    var doThrow: Bool
}

private extension Bool {
    var asInputForThrowingHandler: ThrowingHandlerInput {
        ThrowingHandlerInput(doThrow: self)
    }
}
