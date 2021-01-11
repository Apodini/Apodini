//
//  WebSocketInterfaceExporterTests.swift
//  
//
//  Created by Max Obermeier on 03.01.21.
//

import XCTest
import Vapor
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

    @PathParameter
    var userId: User.ID

    @ComponentBuilder
    var testService: some Component {
        Group("user", $userId) {
            UserHandler(userId: $userId)
        }
    }

    func testParameterRetrieval() throws {
        let handler = ParameterRetrievalTestHandler()
        let endpoint = handler.mockEndpoint()

        let exporter = WebSocketInterfaceExporter(app)
        var context = endpoint.createConnectionContext(for: exporter)

        let bird = Bird(name: "Rudi", age: 12)

        var input = SomeInput(parameters: [
            "bird": NullableOptionalVariableParameter<Bird>(),
            "a": NullableOptionalVariableParameter<UUID>(),
            "param0": NullableOptionalVariableParameter<String>(),
            "pathA": NullableOptionalVariableParameter<String>()
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
        guard case let .automatic(responseValue) = result.typed(Parameters.self) else {
            XCTFail("Expected return value to be wrapped in Response.automatic by default")
            return
        }

        XCTAssertEqual(responseValue.param0, "value0")
        XCTAssertEqual(responseValue.param1, nil)
        XCTAssertEqual(responseValue.pathA, "a")
        XCTAssertEqual(responseValue.pathB, nil)
        XCTAssertEqual(responseValue.bird, bird)
    }

    func testWebSocketConnection() throws {
        let builder = SharedSemanticModelBuilder(app)
            .with(exporter: WebSocketInterfaceExporter.self)
        let visitor = SyntaxTreeVisitor(semanticModelBuilders: [builder])
        testService.accept(visitor)
        visitor.finishParsing()

        try app.start()
        
        let userId = "1234"
        let name = "Rudi"
        
        let promise = app.eventLoopGroup.next().makePromise(of: User.self)
        WebSocket.connect(
            to: "ws://localhost:8080/apodini/websocket",
            on: app.eventLoopGroup.next()
        ) { websocket in
            let contextId = UUID()
            
            // create context on user endpoint
            websocket.send("""
                {
                    "context": "\(contextId.uuidString)",
                    "endpoint": "user.::"
                }
            """)
            
            // send request
            websocket.send("""
                {
                    "context": "\(contextId.uuidString)",
                    "parameters": {
                        "userId": "\(userId)",
                        "name": "\(name)"
                    }
                }
            """)
            
            websocket.onText { websocket, string in
                guard let data = string.data(using: .utf8) else {
                    XCTFail("Could not decode service message. Expected UTF8.")
                    return
                }
                
                // await
                guard let wrappedUser = try? JSONDecoder().decode(DecodedResponseContainer<User>.self, from: data) else {
                    XCTFail("Could not decode service message.")
                    return
                }
                
                promise.succeed(wrappedUser.content)
                
                // close context
                websocket.send("""
                    {
                        "context": "\(contextId.uuidString)"
                    }
                """)
                
                // close connection
                _ = websocket.close()
            }
        }
        .cascadeFailure(to: promise)

        let user = try promise.futureResult.wait()
        
        XCTAssertEqual(user.id, userId)
        XCTAssertEqual(user.name, name)
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
