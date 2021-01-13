//
//  GRPCInterfaceExporterTests.swift
//  
//
//  Created by Moritz Schüll on 20.12.20.
//

import XCTest
@testable import Vapor
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

final class GRPCInterfaceExporterTests: XCTestCase {
    // swiftlint:disable implicitly_unwrapped_optional
    fileprivate var app: Application!
    fileprivate var service: GRPCService!
    fileprivate var handler: GRPCTestHandler!
    fileprivate var endpoint: Endpoint<GRPCTestHandler>!
    fileprivate var exporter: GRPCInterfaceExporter!
    fileprivate var headers: HTTPHeaders!
    // swiftlint:enable implicitly_unwrapped_optional

    fileprivate let serviceName = "TestService"
    fileprivate let methodName = "testMethod"
    fileprivate let requestData1: [UInt8] = [0, 0, 0, 0, 10, 10, 6, 77, 111, 114, 105, 116, 122, 16, 23]
    fileprivate let requestData2: [UInt8] = [0, 0, 0, 0, 9, 10, 5, 66, 101, 114, 110, 100, 16, 65]

    override func setUpWithError() throws {
        try super.setUpWithError()
        app = Application(.testing)
        service = GRPCService(name: serviceName, using: app)
        handler = GRPCTestHandler()
        endpoint = handler.mockEndpoint()
        exporter = GRPCInterfaceExporter(app)
        headers = HTTPHeaders()
        headers.add(name: .contentType, value: "application/grpc+proto")
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        let app = try XCTUnwrap(self.app)
        app.shutdown()
    }

    func testDefaultEndpointNaming() throws {
        let expectedServiceName = "Group1Group2Service"

        let webService = WebServiceModel()

        let handler = GRPCTestHandler()
        var endpoint = handler.mockEndpoint()

        webService.addEndpoint(&endpoint, at: ["Group1", "Group2"])

        let exporter = GRPCInterfaceExporter(app)
        exporter.export(endpoint)

        XCTAssertNotNil(exporter.services[expectedServiceName])
    }

    func testUnaryRequestHandlerWithOneParamater() throws {
        let context = endpoint.createConnectionContext(for: exporter)

        // let expectedResponseString = "Hello Moritz"
        let expectedResponseData: [UInt8] =
            [0, 0, 0, 0, 14, 10, 12, 72, 101, 108, 108, 111, 32, 77, 111, 114, 105, 116, 122]

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let vaporRequest = Vapor.Request(application: app,
                                         method: .POST,
                                         url: URI(path: "https://localhost:8080/\(serviceName)/\(methodName)"),
                                         version: .init(major: 2, minor: 0),
                                         headers: headers,
                                         collectedBody: ByteBuffer(bytes: requestData1),
                                         remoteAddress: nil,
                                         logger: app.logger,
                                         on: group.next())

        let response = try service.createUnaryHandler(context: context)(vaporRequest).wait()
        let responseData = try XCTUnwrap(response.body.data)
        XCTAssertEqual(responseData, Data(expectedResponseData))
    }

    func testUnaryRequestHandlerWithTwoParameters() throws {
        let handler = GRPCTestHandler2()
        let endpoint = handler.mockEndpoint()
        let context = endpoint.createConnectionContext(for: exporter)

        // let expectedResponseString = "Hello Moritz, you are 23 years old."
        let expectedResponseData: [UInt8] = [
            0, 0, 0, 0, 37,
            10, 35, 72, 101, 108, 108, 111, 32, 77,
            111, 114, 105, 116, 122, 44, 32, 121, 111,
            117, 32, 97, 114, 101, 32, 50, 51, 32, 121,
            101, 97, 114, 115, 32, 111, 108, 100, 46
        ]

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let vaporRequest = Vapor.Request(application: app,
                                         method: .POST,
                                         url: URI(path: "https://localhost:8080/\(serviceName)/\(methodName)"),
                                         version: .init(major: 2, minor: 0),
                                         headers: headers,
                                         collectedBody: ByteBuffer(bytes: requestData1),
                                         remoteAddress: nil,
                                         logger: app.logger,
                                         on: group.next())

        let response = try service.createUnaryHandler(context: context)(vaporRequest).wait()
        let responseData = try XCTUnwrap(response.body.data)
        XCTAssertEqual(responseData, Data(expectedResponseData))
    }

    /// Tests the client-streaming handler for a request with
    /// 1 HTTP frame that contains 1 GRPC messages.
    func testClientStreamingHandlerWithOne_1Message_1Frame() throws {
        let contextCreator = {
            self.endpoint.createConnectionContext(for: self.exporter)
        }

        // let expectedResponseString = "Hello Moritz"
        let expectedResponseData: [UInt8] =
            [0, 0, 0, 0, 14, 10, 12, 72, 101, 108, 108, 111, 32, 77, 111, 114, 105, 116, 122]

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let vaporRequest = Vapor.Request(application: app,
                                         method: .POST,
                                         url: URI(path: "https://localhost:8080/\(serviceName)/\(methodName)"),
                                         on: group.next())
        vaporRequest.headers = headers
        let stream = Vapor.Request.BodyStream(on: vaporRequest.eventLoop)
        vaporRequest.bodyStorage = .stream(stream)

        service.createClientStreamingHandler(contextCreator: contextCreator)(vaporRequest)
            .whenSuccess { response in
                guard let responseData = response.body.data else {
                    XCTFail("Received empty response but expected: \(expectedResponseData)")
                    return
                }
                XCTAssertEqual(responseData, Data(expectedResponseData))
            }

        _ = try stream.write(.buffer(ByteBuffer(bytes: requestData1))).wait()
        _ = try stream.write(.end).wait()
    }

    /// Tests the client-streaming handler for a request with
    /// 1 HTTP frame that contains 2 GRPC messages.
    ///
    /// The handler should only return the response for the last (second)
    /// message contained in the frame.
    func testClientStreamingHandlerWithOne_2Messages_1Frame() throws {
        let contextCreator = {
            self.endpoint.createConnectionContext(for: self.exporter)
        }

        let requestData: [UInt8] = [
            0, 0, 0, 0, 10, 10, 6, 77, 111, 114, 105, 116, 122, 16, 23,
            0, 0, 0, 0, 9, 10, 5, 66, 101, 114, 110, 100, 16, 23
        ]
        // let expectedResponseString = "Hello Bernd"
        let expectedResponseData: [UInt8] =
            [0, 0, 0, 0, 13, 10, 11, 72, 101, 108, 108, 111, 32, 66, 101, 114, 110, 100]

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let vaporRequest = Vapor.Request(application: app,
                                         method: .POST,
                                         url: URI(path: "https://localhost:8080/\(serviceName)/\(methodName)"),
                                         on: group.next())
        vaporRequest.headers = headers
        let stream = Vapor.Request.BodyStream(on: vaporRequest.eventLoop)
        vaporRequest.bodyStorage = .stream(stream)

        service.createClientStreamingHandler(contextCreator: contextCreator)(vaporRequest)
            .whenSuccess { response in
                guard let responseData = response.body.data else {
                    XCTFail("Received empty response but expected: \(expectedResponseData)")
                    return
                }
                XCTAssertEqual(responseData, Data(expectedResponseData))
            }

        _ = try stream.write(.buffer(ByteBuffer(bytes: requestData))).wait()
        _ = try stream.write(.end).wait()
    }

    /// Tests the client-streaming handler for a request with
    /// 2 HTTP frames that contain 2 GRPC messages.
    /// (each message comes in its own frame)
    ///
    /// The handler should only return the response for the last (second)
    /// message contained in the frame.
    func testClientStreamingHandlerWithOne_2Messages_2Frames() throws {
        let contextCreator = {
            self.endpoint.createConnectionContext(for: self.exporter)
        }

        // let expectedResponseString = "Hello Bernd"
        let expectedResponseData: [UInt8] =
            [0, 0, 0, 0, 13, 10, 11, 72, 101, 108, 108, 111, 32, 66, 101, 114, 110, 100]

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let vaporRequest = Vapor.Request(application: app,
                                         method: .POST,
                                         url: URI(path: "https://localhost:8080/\(serviceName)/\(methodName)"),
                                         on: group.next())
        vaporRequest.headers = headers
        let stream = Vapor.Request.BodyStream(on: vaporRequest.eventLoop)
        vaporRequest.bodyStorage = .stream(stream)

        // get first response
        service.createClientStreamingHandler(contextCreator: contextCreator)(vaporRequest)
            .whenSuccess { response in
                guard let responseData = response.body.data else {
                    XCTFail("Received empty response but expected: \(expectedResponseData)")
                    return
                }
                // Expect empty response data for first GRPC message,
                // because it was not the end yet.
                XCTAssertEqual(responseData, Data(expectedResponseData))
            }

        // write messages individually
        _ = try stream.write(.buffer(ByteBuffer(bytes: requestData1))).wait()
        _ = try stream.write(.buffer(ByteBuffer(bytes: requestData2))).wait()
        _ = try stream.write(.end).wait()
    }
}
