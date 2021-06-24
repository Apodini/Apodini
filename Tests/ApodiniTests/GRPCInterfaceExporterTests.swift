//
//  GRPCInterfaceExporterTests.swift
//  
//
//  Created by Moritz Schüll on 20.12.20.
//

import XCTest
@testable import Apodini
@testable import Vapor
@testable import ApodiniGRPC

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

private struct GRPCNothingHandler: Handler {
    func handle() -> Apodini.Response<Int32> {
        .nothing
    }
}

final class GRPCInterfaceExporterTests: ApodiniTests {
    // swiftlint:disable implicitly_unwrapped_optional
    fileprivate var exporterConfiguration: GRPC.ExporterConfiguration!
    fileprivate var service: GRPCService!
    fileprivate var handler: GRPCTestHandler!
    fileprivate var endpoint: Endpoint<GRPCTestHandler>!
    fileprivate var rendpoint: RelationshipEndpoint<GRPCTestHandler>!
    fileprivate var exporter: GRPCInterfaceExporter!
    fileprivate var headers: HTTPHeaders!
    // swiftlint:enable implicitly_unwrapped_optional

    fileprivate let serviceName = "TestService"
    fileprivate let methodName = "testMethod"
    fileprivate let requestData1: [UInt8] = [0, 0, 0, 0, 10, 10, 6, 77, 111, 114, 105, 116, 122, 16, 23]
    fileprivate let requestData2: [UInt8] = [0, 0, 0, 0, 9, 10, 5, 66, 101, 114, 110, 100, 16, 65]

    override func setUpWithError() throws {
        try super.setUpWithError()
        exporterConfiguration = GRPC.ExporterConfiguration()
        service = GRPCService(name: serviceName, using: app, exporterConfiguration)
        handler = GRPCTestHandler()
        (endpoint, rendpoint) = handler.mockRelationshipEndpoint()
        exporter = GRPCInterfaceExporter(app)
        headers = HTTPHeaders()
        headers.add(name: .contentType, value: "application/grpc+proto")
    }

    func testDefaultEndpointNaming() throws {
        struct TestWebService: WebService {
            var content: some Component {
                Group("Group1") {
                    Group("Group2") {
                        GRPCTestHandler()
                    }
                }
            }
        }
        
        let expectedServiceName = "Group1Group2Service"

        let modelBuilder = SemanticModelBuilder(app)
        let visitor = SyntaxTreeVisitor(modelBuilder: modelBuilder)
        TestWebService().accept(visitor)
        visitor.finishParsing()
        
        let endpoint = try XCTUnwrap(modelBuilder.collectedEndpoints.first as? Endpoint<GRPCTestHandler>)

        let exporter = GRPCInterfaceExporter(app)
        exporter.export(endpoint)
        print(exporter.services)
        XCTAssertNotNil(exporter.services[expectedServiceName])
    }

    /// Checks that the GRPC exporter considers `.serviceName` context
    /// values for naming services.
    func testExplicitEndpointNaming() throws {
        let expectedServiceName = "MyService"

        let webService = RelationshipWebServiceModel()

        let handler = GRPCTestHandler()
        let node = ContextNode()
        node.addContext(GRPCServiceNameContextKey.self, value: expectedServiceName, scope: .current)
        var (endpoint, rendpoint) = handler.mockRelationshipEndpoint(context: Context(contextNode: node))

        webService.addEndpoint(&rendpoint, at: ["Group1", "Group2"])

        let exporter = GRPCInterfaceExporter(app)
        exporter.export(endpoint)

        XCTAssertNotNil(exporter.services[expectedServiceName])
    }

    func testShouldAcceptMultipleEndpoints() throws {
        let context = endpoint.createConnectionContext(for: exporter)

        try service.exposeUnaryEndpoint(name: "endpointName1", context: context)
        XCTAssertNoThrow(try service.exposeUnaryEndpoint(name: "endpointName2", context: context))
        XCTAssertNoThrow(try service.exposeClientStreamingEndpoint(name: "endpointName3", context: context))
    }

    func testShouldNotOverwriteExistingEndpoint() throws {
        let context = endpoint.createConnectionContext(for: exporter)

        try service.exposeUnaryEndpoint(name: "endpointName", context: context)
        XCTAssertThrowsError(try service.exposeUnaryEndpoint(name: "endpointName", context: context))
        XCTAssertThrowsError(try service.exposeClientStreamingEndpoint(name: "endpointName", context: context))
    }

    func testShouldRequireContentTypeHeader() throws {
        let context = endpoint.createConnectionContext(for: exporter)

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let vaporRequest = Vapor.Request(application: app.vapor.app,
                                         method: .POST,
                                         url: URI(path: "https://localhost:8080/\(serviceName)/\(methodName)"),
                                         version: .init(major: 2, minor: 0),
                                         headers: .init(),
                                         collectedBody: ByteBuffer(bytes: requestData1),
                                         remoteAddress: nil,
                                         logger: app.logger,
                                         on: group.next())

        var handler = service.createUnaryHandler(context: context)
        XCTAssertThrowsError(try handler(vaporRequest).wait())

        handler = service.createClientStreamingHandler(context: context)
        XCTAssertThrowsError(try handler(vaporRequest).wait())
    }

    func testUnaryRequestHandlerWithOneParamater() throws {
        let context = endpoint.createConnectionContext(for: exporter)

        // let expectedResponseString = "Hello Moritz"
        let expectedResponseData: [UInt8] =
            [0, 0, 0, 0, 14, 10, 12, 72, 101, 108, 108, 111, 32, 77, 111, 114, 105, 116, 122]

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let vaporRequest = Vapor.Request(application: app.vapor.app,
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
        let vaporRequest = Vapor.Request(application: app.vapor.app,
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

    /// Tests request validation for the GRPC exporter.
    /// Should throw for a payload that does not contain data for all required parameters.
    func testUnaryRequestHandlerRequiresAllParameters() throws {
        let endpoint = GRPCTestHandler2().mockEndpoint()
        let context = endpoint.createConnectionContext(for: exporter)

        let incompleteData: [UInt8] = [0, 0, 0, 0, 8, 10, 6, 77, 111, 114, 105, 116, 122]

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let vaporRequest = Vapor.Request(application: app.vapor.app,
                                         method: .POST,
                                         url: URI(path: "https://localhost:8080/\(serviceName)/\(methodName)"),
                                         version: .init(major: 2, minor: 0),
                                         headers: headers,
                                         collectedBody: ByteBuffer(bytes: incompleteData),
                                         remoteAddress: nil,
                                         logger: app.logger,
                                         on: group.next())

        let handler = service.createUnaryHandler(context: context)
        XCTAssertThrowsError(try handler(vaporRequest).wait())
    }

    /// The unary handler should only consider the first message in case
    /// it receives multiple messages in one HTTP frame.
    func testUnaryRequestHandler_2Messages_1Frame() throws {
        let context = endpoint.createConnectionContext(for: exporter)

        // First one is "Moritz", second one is "Bernd".
        // Only the first should be considered.
        let requestData: [UInt8] = [
            0, 0, 0, 0, 10, 10, 6, 77, 111, 114, 105, 116, 122, 16, 23,
            0, 0, 0, 0, 9, 10, 5, 66, 101, 114, 110, 100, 16, 23
        ]

        // let expectedResponseString = "Hello Moritz"
        let expectedResponseData: [UInt8] =
            [0, 0, 0, 0, 14, 10, 12, 72, 101, 108, 108, 111, 32, 77, 111, 114, 105, 116, 122]

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let vaporRequest = Vapor.Request(application: app.vapor.app,
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

    /// Tests the client-streaming handler for a request with
    /// 1 HTTP frame that contains 1 GRPC messages.
    func testClientStreamingHandlerWith_1Message_1Frame() throws {
        let context = endpoint.createConnectionContext(for: self.exporter)

        // let expectedResponseString = "Hello Moritz"
        let expectedResponseData: [UInt8] =
            [0, 0, 0, 0, 14, 10, 12, 72, 101, 108, 108, 111, 32, 77, 111, 114, 105, 116, 122]

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let vaporRequest = Vapor.Request(application: app.vapor.app,
                                         method: .POST,
                                         url: URI(path: "https://localhost:8080/\(serviceName)/\(methodName)"),
                                         on: group.next())
        vaporRequest.headers = headers
        let stream = Vapor.Request.BodyStream(on: vaporRequest.eventLoop)
        vaporRequest.bodyStorage = .stream(stream)

        service.createClientStreamingHandler(context: context)(vaporRequest)
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
    func testClientStreamingHandlerWith_2Messages_1Frame() throws {
        let context = endpoint.createConnectionContext(for: self.exporter)

        let requestData: [UInt8] = [
            0, 0, 0, 0, 10, 10, 6, 77, 111, 114, 105, 116, 122, 16, 23,
            0, 0, 0, 0, 9, 10, 5, 66, 101, 114, 110, 100, 16, 23
        ]
        // let expectedResponseString = "Hello Bernd"
        let expectedResponseData: [UInt8] =
            [0, 0, 0, 0, 13, 10, 11, 72, 101, 108, 108, 111, 32, 66, 101, 114, 110, 100]

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let vaporRequest = Vapor.Request(application: app.vapor.app,
                                         method: .POST,
                                         url: URI(path: "https://localhost:8080/\(serviceName)/\(methodName)"),
                                         on: group.next())
        vaporRequest.headers = headers
        let stream = Vapor.Request.BodyStream(on: vaporRequest.eventLoop)
        vaporRequest.bodyStorage = .stream(stream)

        service.createClientStreamingHandler(context: context)(vaporRequest)
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
    func testClientStreamingHandlerWith_2Messages_2Frames() throws {
        let context = endpoint.createConnectionContext(for: self.exporter)

        // let expectedResponseString = "Hello Bernd"
        let expectedResponseData: [UInt8] =
            [0, 0, 0, 0, 13, 10, 11, 72, 101, 108, 108, 111, 32, 66, 101, 114, 110, 100]

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let vaporRequest = Vapor.Request(application: app.vapor.app,
                                         method: .POST,
                                         url: URI(path: "https://localhost:8080/\(serviceName)/\(methodName)"),
                                         on: group.next())
        vaporRequest.headers = headers
        let stream = Vapor.Request.BodyStream(on: vaporRequest.eventLoop)
        vaporRequest.bodyStorage = .stream(stream)

        // get first response
        service.createClientStreamingHandler(context: context)(vaporRequest)
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

    /// Checks whether the returned response for a `.nothing` is indeed empty.
    func testClientStreamingHandlerNothingResponse() throws {
        let handler = GRPCNothingHandler()
        let endpoint = handler.mockEndpoint()
        let context = endpoint.createConnectionContext(for: self.exporter)

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let vaporRequest = Vapor.Request(application: app.vapor.app,
                                         method: .POST,
                                         url: URI(path: "https://localhost:8080/\(serviceName)/\(methodName)"),
                                         on: group.next())
        vaporRequest.headers = headers
        let stream = Vapor.Request.BodyStream(on: vaporRequest.eventLoop)
        vaporRequest.bodyStorage = .stream(stream)

        service.createClientStreamingHandler(context: context)(vaporRequest)
            .whenSuccess { response in
                XCTAssertEqual(response.body.data,
                               Optional(Data()),
                               "Received non-empty response but expected empty response")
            }

        _ = try stream.write(.buffer(ByteBuffer(bytes: requestData1))).wait()
        _ = try stream.write(.end).wait()
    }

    func testServiceNameUtility_DefaultName() throws {
        struct TestWebService: WebService {
            var content: some Component {
                Group("Group1") {
                    Group("Group2") {
                        GRPCTestHandler()
                    }
                }
            }
        }
        
        let expectedServiceName = "Group1Group2Service"

        let modelBuilder = SemanticModelBuilder(app)
        let visitor = SyntaxTreeVisitor(modelBuilder: modelBuilder)
        TestWebService().accept(visitor)
        visitor.finishParsing()
        
        let endpoint = try XCTUnwrap(modelBuilder.collectedEndpoints.first as? Endpoint<GRPCTestHandler>)

        XCTAssertEqual(gRPCServiceName(from: endpoint), expectedServiceName)
    }

    func testServiceNameUtility_CustomName() {
        let serviceName = "TestService"

        let node = ContextNode()
        node.addContext(GRPCServiceNameContextKey.self, value: serviceName, scope: .current)
        endpoint = handler.mockEndpoint(context: Context(contextNode: node))

        XCTAssertEqual(gRPCServiceName(from: endpoint), serviceName)
    }

    func testMethodNameUtility_DefaultName() {
        XCTAssertEqual(gRPCMethodName(from: endpoint), "grpctesthandler")
    }

    func testMethodNameUtility_CustomName() {
        let methodName = "testMethod"

        let node = ContextNode()
        node.addContext(GRPCMethodNameContextKey.self, value: methodName, scope: .current)
        endpoint = handler.mockEndpoint(context: Context(contextNode: node))

        XCTAssertEqual(gRPCMethodName(from: endpoint), methodName)
    }
}
