//
//  GRPCInterfaceExporterTests.swift
//  
//
//  Created by Moritz Schüll on 20.12.20.
//

import XCTest
import Vapor
@testable import Apodini

private struct GRPCTestHandler: Handler {
    @Parameter("name",
               .gRPC(.fieldTag(1)))
    var name: String

    func handle() -> String {
        "Hello \(name)"
    }
}

private struct GRPCTestHandler2: Handler {
    @Parameter("name",
               .gRPC(.fieldTag(1)))
    var name: String
    @Parameter("age",
               .gRPC(.fieldTag(2)))
    var age: Int32

    func handle() -> String {
        "Hello \(name), you are \(age) years old."
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

final class GRPCInterfaceExporterTests: XCTestCase {
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

    func testUnaryRequestHandlerWithOneParamater() throws {
        let serviceName = "TestService"
        let methodName = "testMethod"
        let service = GRPCService(name: serviceName, using: app)
        let handler = GRPCTestHandler()
        let endpoint = handler.mockEndpoint()

        let exporter = GRPCInterfaceExporter(app)
        let context = endpoint.createConnectionContext(for: exporter)

        let requestData: [UInt8] =
            [0, 0, 0, 0, 10, 10, 6, 77, 111, 114, 105, 116, 122, 16, 23]
        // let expectedResponseString = "Hello Moritz"
        let expectedResponseData: [UInt8] =
            [0, 0, 0, 0, 14, 10, 12, 72, 101, 108, 108, 111, 32, 77, 111, 114, 105, 116, 122]

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

        let response = try service.createUnaryHandler(context: context)(vaporRequest).wait()
        let responseData = try XCTUnwrap(response.body.data)
        XCTAssertEqual(responseData, Data(expectedResponseData))
    }

    func testUnaryRequestHandlerWithTwoParameters() throws {
        let serviceName = "TestService"
        let methodName = "testMethod"
        let service = GRPCService(name: serviceName, using: app)
        let handler = GRPCTestHandler2()
        let endpoint = handler.mockEndpoint()

        let exporter = GRPCInterfaceExporter(app)
        let context = endpoint.createConnectionContext(for: exporter)

        let requestData: [UInt8] =
            [0, 0, 0, 0, 10, 10, 6, 77, 111, 114, 105, 116, 122, 16, 23]
        // let expectedResponseString = "Hello Moritz, you are 23 years old."
        let expectedResponseData: [UInt8] = [
            0, 0, 0, 0, 37,
            10, 35, 72, 101, 108, 108, 111, 32, 77,
            111, 114, 105, 116, 122, 44, 32, 121, 111,
            117, 32, 97, 114, 101, 32, 50, 51, 32, 121,
            101, 97, 114, 115, 32, 111, 108, 100, 46
        ]

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

        let response = try service.createUnaryHandler(context: context)(vaporRequest).wait()
        let responseData = try XCTUnwrap(response.body.data)
        XCTAssertEqual(responseData, Data(expectedResponseData))
    }
}
