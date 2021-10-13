//
//  DecodingStrategiesTests.swift
//  
//
//  Created by Max Obermeier on 04.07.21.
//

import XCTApodini
import ApodiniVaporSupport
import Vapor
@testable import Apodini
import ApodiniExtension
import XCTVapor


typealias Request = Vapor.Request


class DecodingStrategiesTests: XCTApodiniTest {
    struct MockHandler: Handler {
        func handle() -> String { "" }
    }
    
    func testEmptyBody() throws {
        let eventLoop = app.eventLoopGroup.next()
        
        let request = Request(
            application: app.vapor.app,
            method: .GET,
            url: URI(path: "/"),
            on: eventLoop
        )
        
        XCTAssertEqual(request.bodyData.count, 0)
    }
    
    func testTransformingStrategy() throws {
        let eventLoop = app.eventLoopGroup.next()
        
        let request = Request(
            application: app.vapor.app,
            method: .PUT,
            url: URI(path: "/"),
            collectedBody: ByteBuffer(string: "\"Hello, World!\""),
            on: eventLoop
        )
        
        let parameter = Parameter<String>()
        
        let strategy = singleParameterStrategy(for: parameter).transformedToVaporRequestBasedStrategy()
        
        XCTAssertEqual(try strategy.strategy(for: parameter).decode(from: request), "Hello, World!")
    }
    
    func testPathParameterStrategyThrowing() throws {
        let eventLoop = app.eventLoopGroup.next()
        
        let request = Request(
            application: app.vapor.app,
            method: .GET,
            url: URI(path: "/"),
            on: eventLoop
        )
        
        let parameter = Parameter<String>(.http(.path))
        let endpoint = try XCTCreateMockEndpoint(MockHandler())
        endpoint[EndpointParameters.self] = [
            EndpointParameter<String>(
                id: parameter.id,
                name: "",
                label: "",
                nilIsValidValue: false,
                necessity: .required,
                options: parameter.options,
                defaultValue: nil
            )
        ]
        
        let strategy = PathStrategy(useNameAsIdentifier: false).applied(to: endpoint)
        
        XCTAssertThrowsError(try strategy.strategy(for: parameter).decode(from: request))
    }
    
    private func singleParameterStrategy<Value>(for parameter: Parameter<Value>) -> AnyDecodingStrategy<Data> {
        (IdentifierBasedStrategy<Data>()
            .with(strategy: PlainPatternStrategy<IdentityPattern<String>>(JSONDecoder()), for: parameter)
            .typeErased as AnyBaseDecodingStrategy<Data>)
            .typeErased
    }
}
