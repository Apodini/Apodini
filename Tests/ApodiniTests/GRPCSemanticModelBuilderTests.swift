//
//  GRPCSemanticModelBuilder.swift
//  
//
//  Created by Moritz Schüll on 20.12.20.
//

import XCTest
import Vapor
@testable import Apodini

private struct GRPCTestHandler: Component {
    @Parameter("name",
               .gRPC(.fieldTag(1)))
    var name: String

    func handle() -> String {
        "Hello \(name)"
    }
}

private struct GRPCTestComponent1: Component {
    var content: some Component {
        Group("a") {
            Group("b") {
                GRPCTestHandler()
            }
        }
    }
}

private struct GRPCTestComponent2: Component {
    var content: some Component {
        Group("a") {
            Group("b") {
                GRPCTestHandler()
                    .serviceName("TestService")
                    .rpcName("testMethod")
            }
        }
    }
}

final class GRPCSemanticModelBuilderTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    var app: Application!

    override func setUpWithError() throws {
        try super.setUpWithError()
        app = Application(.testing)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        let app = try XCTUnwrap(self.app)
        app.shutdown()
    }

    func testDefaultServiceNaming() {
        // swiftlint:disable force_unwrapping
        let modelBuilder = GRPCSemanticModelBuilder(app)
        let visitor = SyntaxTreeVisitor(semanticModelBuilders: [modelBuilder])
        let testComponent = GRPCTestComponent1()
        Group {
            testComponent.content
        }.visit(visitor)

        let expectedServiceName = "ab"
        XCTAssertNotNil(modelBuilder.services[expectedServiceName])
        XCTAssertNil(modelBuilder.services["something"])
    }

    func testServiceNameModifier() {
        // swiftlint:disable force_unwrapping
        let modelBuilder = GRPCSemanticModelBuilder(app)
        let visitor = SyntaxTreeVisitor(semanticModelBuilders: [modelBuilder])
        let testComponent = GRPCTestComponent2()
        Group {
            testComponent.content
        }.visit(visitor)

        let expectedServiceName = "TestService"
        XCTAssertNotNil(modelBuilder.services[expectedServiceName])
        XCTAssertNil(modelBuilder.services["something"])
    }

    func testUnaryRequestHandler() throws {
        // swiftlint:disable force_unwrapping
        let serviceName = "TestService"
        let methodName = "testMethod"
        let service =  GRPCService(name: serviceName, using: app)

        let requestData: [UInt8] =
            [0, 0, 0, 0, 10, 10, 6, 77, 111, 114, 105, 116, 122, 16, 23]
        let expectedResponseString = "Hello Moritz"
//        let expectedResponseData: [UInt8] =
//            [0, 0, 0, 0, 14, 10, 12, 72, 101, 108, 108, 111, 32, 77, 111, 114, 105, 116, 122]

        var headers = HTTPHeaders()
        headers.add(name: .contentType, value: "application/grpc+proto")
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let vaporRequest = Vapor.Request(application: app,
                                    method: .POST,
                                    url: URI(path: "https://localhost:8080/\(serviceName)/\(methodName)"),
                                    version: .init(major: 2, minor: 0),
                                    headers: headers,
                                    collectedBody: ByteBuffer(bytes: requestData),
                                    remoteAddress: nil,
                                    logger: app.logger,
                                    on: group.next())

        let requestHandler = service.createUnaryHandler(for: GRPCTestHandler(),
                                                        with: Context(contextNode: ContextNode()))
        let resultString = try requestHandler(GRPCRequest(vaporRequest)).wait()
        XCTAssertEqual(resultString, expectedResponseString)
    }
}
