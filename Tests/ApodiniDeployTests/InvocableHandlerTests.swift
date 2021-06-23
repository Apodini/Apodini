//
//  InvocableHandlerTests.swift
//  
//
//  Created by Lukas Kollmer on 2021-01-17.
//

// swiftlint:disable identifier_name type_name nesting

import Foundation
@testable import Apodini
import ApodiniREST
import XCTApodini
import Vapor
@testable import ApodiniVaporSupport
import XCTVapor
import XCTest
import ApodiniDeploy


struct WrappedRESTResponse<T: Codable>: Vapor.Content {
    let data: T
}

extension Vapor.ContentContainer {
    func decodeRESTResponseData<T: Codable>(_ type: T.Type) throws -> T {
        try self.decode(WrappedRESTResponse<T>.self).data
    }
}


private struct TestWebService: Apodini.WebService {
    struct F: InvocableHandler {
        class HandlerIdentifier: ScopedHandlerIdentifier<F> {
            static let main = HandlerIdentifier("main")
        }
        let handlerId = HandlerIdentifier.main
        func handle() -> String {
            "F"
        }
    }
    
    struct FInvoker: Handler {
        @Apodini.Environment(\.RHI) private var RHI
        
        func handle() -> EventLoopFuture<String> {
            RHI.invoke(F.self, identifiedBy: .main)
        }
    }
    
    
    struct TextTransformer: InvocableHandler {
        enum Transformation: String, Codable, LosslessStringConvertible {
            case identity
            case capitalize
            case makeLowercase
            case makeUppercase
            case makeSpongebobcase
            
            init?(_ description: String) {
                if let value = Self(rawValue: description) {
                    self = value
                } else {
                    return nil
                }
            }
            var description: String { rawValue }
        }
        
        class HandlerIdentifier: ScopedHandlerIdentifier<TextTransformer> {
            static let main = HandlerIdentifier("main")
        }
        let handlerId = HandlerIdentifier.main
        
        @Parameter var transformation: Transformation = .identity
        @Parameter var input: String
        
        func handle() -> String {
            switch transformation {
            case .identity:
                return input
            case .capitalize:
                return input
                    .split(separator: " ")
                    .map { $0.enumerated().map { $0.offset == 0 ? $0.element.uppercased() : String($0.element) }.joined() }
                    .joined(separator: " ")
            case .makeLowercase:
                return input.lowercased()
            case .makeUppercase:
                return input.uppercased()
            case .makeSpongebobcase:
                return input.map { .random() ? $0.uppercased() : $0.lowercased() }.joined()
            }
        }
    }


    struct Greeter: Handler {
        @Apodini.Environment(\.RHI) private var RHI
        
        @Parameter var name: String
        @Parameter var transformation: TextTransformer.Transformation?
        
        func handle() -> EventLoopFuture<String> {
            // we use the presence of the transformation parameter to test whether the RHI properly handles default parameter values
            let nameFuture = { () -> EventLoopFuture<String> in
                if let transformation = transformation {
                    return RHI.invoke(TextTransformer.self, identifiedBy: .main, arguments: [
                        .init(\.$transformation, transformation),
                        .init(\.$input, name)
                    ])
                } else {
                    return RHI.invoke(TextTransformer.self, identifiedBy: .main, arguments: [
                        .init(\.$input, name)
                    ])
                }
            }()
            return nameFuture.map { "Hello \($0)!" }
        }
    }
    
    
    struct Adder: InvocableHandler {
        struct ArgumentsStorage: ArgumentsStorageProtocol {
            typealias HandlerType = Adder
            let x: Double
            let y: Double
            
            init(x: Double, y: Double) {
                self.x = x
                self.y = y
            }
            
            init(x: Int, y: Int) {
                self.x = Double(x)
                self.y = Double(y)
            }
            
            static let mapping: [MappingEntry] = [
                .init(from: \.x, to: \.$x),
                .init(from: \.y, to: \.$y)
            ]
        }
        class HandlerIdentifier: ScopedHandlerIdentifier<Adder> {
            static let main = HandlerIdentifier("main")
        }
        
        let handlerId = HandlerIdentifier.main
        
        @Parameter var x: Double
        @Parameter var y: Double
        
        func handle() throws -> Double {
            x + y
        }
    }
    
    
    struct Calculator: Handler {
        @Apodini.Environment(\.RHI) private var RHI
        
        @Parameter var operation: String
        @Parameter var lhs: Int
        @Parameter var rhs: Int
        
        func handle() throws -> EventLoopFuture<Int> {
            switch operation {
            default:
                return RHI.invoke(Adder.self, identifiedBy: .main, arguments: .init(x: lhs, y: rhs)).map(Int.init)
            }
        }
    }

    
    var content: some Component {
        Group("_f") {
            F()
        }
        Group("f") {
            FInvoker()
        }
        Group("transform", "text") {
            TextTransformer()
        }
        Group("greet") {
            Greeter()
        }
        Group("calc") {
            Calculator()
            Group("add") {
                Adder()
            }
        }
    }
    
    var configuration: Configuration {
        REST()
        ApodiniDeploy()
    }
}


class InvocableHandlerTests: XCTApodiniTest {
    func testSimpleRemoteHandlerInvocation() throws {
        TestWebService.start(app: app)
        try app.vapor.app.test(.GET, "/v1/f") { res in
            XCTAssertEqual(res.status, .ok)
            try XCTAssertEqual(res.content.decodeRESTResponseData(String.self), "F")
        }
    }
    
    func testArrayBasedParameterPassing() throws {
        TestWebService.start(app: app)
        try app.vapor.app.test(
            .GET,
            "/v1/greet?name=lukas&transformation=\(TestWebService.TextTransformer.Transformation.makeUppercase.rawValue)"
        ) { res in
            XCTAssertEqual(res.status, .ok)
            try XCTAssertEqual(res.content.decodeRESTResponseData(String.self), "Hello LUKAS!")
        }
    }
    
    func testArrayBasedParameterPassingDefaultParameterValueHandling() throws {
        TestWebService.start(app: app)
        try app.vapor.app.test(.GET, "/v1/greet?name=LuKAs") { res in // default value for the TextTransformer.transformation parameter is .identity
            XCTAssertEqual(res.status, .ok)
            try XCTAssertEqual(res.content.decodeRESTResponseData(String.self), "Hello LuKAs!")
        }
    }
    
    func testParametersStorageObjectBasedParameterPassing() throws {
        TestWebService.start(app: app)
        try app.vapor.app.test(.GET, "/v1/calc?operation=add&lhs=5&rhs=7") { res in
            XCTAssertEqual(res.status, .ok)
            try XCTAssertEqual(res.content.decodeRESTResponseData(Int.self), 12)
        }
    }
}
