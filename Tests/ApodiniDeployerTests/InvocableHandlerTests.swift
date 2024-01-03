//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

// swiftlint:disable identifier_name type_name nesting

import XCTest
import Foundation
@testable import Apodini
import ApodiniREST
import XCTApodini
import ApodiniDeployer
import XCTApodiniNetworking


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
        
        func handle() async throws -> String {
            try await RHI.invoke(F.self, identifiedBy: .main)
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
        
        func handle() async throws -> String {
            // we use the presence of the transformation parameter to test whether the RHI properly handles default parameter values
            let greetingName: String
            if let transformation = transformation {
                greetingName = try await RHI.invoke(TextTransformer.self, identifiedBy: .main, arguments: [
                    .init(\.$transformation, transformation),
                    .init(\.$input, name)
                ])
            } else {
                greetingName = try await RHI.invoke(TextTransformer.self, identifiedBy: .main, arguments: [
                    .init(\.$input, name)
                ])
            }
            return "Hello \(greetingName)!"
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
        
        func handle() async throws -> Int {
            Int(try await RHI.invoke(Adder.self, identifiedBy: .main, arguments: Adder.ArgumentsStorage(x: lhs, y: rhs)))
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
    
    var configuration: any Configuration {
        REST()
        ApodiniDeployer()
    }
}

class InvocableHandlerTests: XCTApodiniTest {
    func testSimpleRemoteHandlerInvocation() throws {
        try TestWebService().start(app: app)
        try app.testable().test(.GET, "/f") { res in
            XCTAssertEqual(res.status, .ok)
            try XCTAssertEqual(XCTUnwrapRESTResponseData(String.self, from: res), "F")
        }
    }
    
    func testArrayBasedParameterPassing() throws {
        try TestWebService().start(app: app)
        try app.testable().test(
            .GET,
            "/greet?name=lukas&transformation=\(TestWebService.TextTransformer.Transformation.makeUppercase.rawValue)"
        ) { res in
            XCTAssertEqual(res.status, .ok)
            try XCTAssertEqual(XCTUnwrapRESTResponseData(String.self, from: res), "Hello LUKAS!")
        }
    }
    
    func testArrayBasedParameterPassingDefaultParameterValueHandling() throws {
        try TestWebService().start(app: app)
        try app.testable().test(.GET, "/greet?name=LuKAs") { res in // default value for the TextTransformer.transformation parameter is .identity
            XCTAssertEqual(res.status, .ok)
            try XCTAssertEqual(XCTUnwrapRESTResponseData(String.self, from: res), "Hello LuKAs!")
        }
    }
    
    func testParametersStorageObjectBasedParameterPassing() throws {
        try TestWebService().start(app: app)
        try app.testable().test(.GET, "/calc?operation=add&lhs=5&rhs=7") { res in
            XCTAssertEqual(res.status, .ok)
            try XCTAssertEqual(XCTUnwrapRESTResponseData(Int.self, from: res), 12)
        }
    }
}
