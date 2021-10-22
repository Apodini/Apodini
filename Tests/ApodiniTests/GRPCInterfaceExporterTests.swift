//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import XCTest
@testable import Apodini
@testable import ApodiniGRPC
import ApodiniExtension
import XCTApodiniNetworking


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
        headers[.contentType] = .gRPCProto
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
        
        let expectedServiceName = "V1Group1Group2Service"

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
        var (endpoint, rendpoint) = handler.mockRelationshipEndpoint(context: node.export())

        webService.addEndpoint(&rendpoint, at: ["Group1", "Group2"])

        let exporter = GRPCInterfaceExporter(app)
        exporter.export(endpoint)

        XCTAssertNotNil(exporter.services[expectedServiceName])
    }

    
    func testShouldAcceptMultipleEndpoints() throws {
        let decodingStrategy = InterfaceExporterLegacyStrategy(exporter).applied(to: endpoint)
        
        try service.exposeUnaryEndpoint(name: "endpointName1", endpoint, strategy: decodingStrategy)
        XCTAssertNoThrow(try service.exposeUnaryEndpoint(name: "endpointName2", endpoint, strategy: decodingStrategy))
        XCTAssertNoThrow(try service.exposeClientStreamingEndpoint(name: "endpointName3", endpoint, strategy: decodingStrategy))
    }

    
    func testShouldNotOverwriteExistingEndpoint() throws {
        let decodingStrategy = InterfaceExporterLegacyStrategy(exporter).applied(to: endpoint)
        
        try service.exposeUnaryEndpoint(name: "endpointName", endpoint, strategy: decodingStrategy)
        XCTAssertThrowsError(try service.exposeUnaryEndpoint(name: "endpointName", endpoint, strategy: decodingStrategy))
        XCTAssertThrowsError(try service.exposeClientStreamingEndpoint(name: "endpointName", endpoint, strategy: decodingStrategy))
    }

    
    func testShouldRequireContentTypeHeader() throws {
        let decodingStrategy = InterfaceExporterLegacyStrategy(exporter).applied(to: endpoint)
        
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let request = HTTPRequest(
            version: .http2,
            method: .POST,
            url: URI("https://localhost:8080/\(serviceName)/\(methodName)")!,
            headers: [:],
            bodyStorage: .buffer(initialValue: requestData1),
            eventLoop: group.next()
        )

        var handler = service.createUnaryHandler(
            factory: endpoint[DelegateFactory<GRPCTestHandler, GRPCInterfaceExporter>.self],
            strategy: decodingStrategy,
            defaults: endpoint[DefaultValueStore.self]
        )
        XCTAssertThrowsError(try handler(request).wait())

        handler = service.createClientStreamingHandler(
            factory: endpoint[DelegateFactory<GRPCTestHandler, GRPCInterfaceExporter>.self],
            strategy: decodingStrategy,
            defaults: endpoint[DefaultValueStore.self])
        XCTAssertThrowsError(try handler(request).wait())
    }

    
    func testUnaryRequestHandlerWithOneParamater() throws {
        let decodingStrategy = InterfaceExporterLegacyStrategy(exporter).applied(to: endpoint)
        
        // let expectedResponseString = "Hello Moritz"
        let expectedResponseData: [UInt8] =
            [0, 0, 0, 0, 14, 10, 12, 72, 101, 108, 108, 111, 32, 77, 111, 114, 105, 116, 122]

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let request = HTTPRequest(
            version: .http2,
            method: .POST,
            url: URI("https://localhost:8080/\(serviceName)/\(methodName)")!,
            headers: headers,
            bodyStorage: .buffer(initialValue: requestData1),
            eventLoop: group.next()
        )

        let response = try service.createUnaryHandler(
            factory: endpoint[DelegateFactory<GRPCTestHandler, GRPCInterfaceExporter>.self],
            strategy: decodingStrategy,
            defaults: endpoint[DefaultValueStore.self]
        )(request).wait()
        let responseData = try XCTUnwrap(response.bodyStorage.getFullBodyData())
        XCTAssertEqual(responseData, Data(expectedResponseData))
    }

    
    func testUnaryRequestHandlerWithTwoParameters() throws {
        let handler = GRPCTestHandler2()
        let endpoint = handler.mockEndpoint()
        
        let decodingStrategy = InterfaceExporterLegacyStrategy(exporter).applied(to: endpoint)

        // let expectedResponseString = "Hello Moritz, you are 23 years old."
        let expectedResponseData: [UInt8] = [
            0, 0, 0, 0, 37,
            10, 35, 72, 101, 108, 108, 111, 32, 77,
            111, 114, 105, 116, 122, 44, 32, 121, 111,
            117, 32, 97, 114, 101, 32, 50, 51, 32, 121,
            101, 97, 114, 115, 32, 111, 108, 100, 46
        ]

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let request = HTTPRequest(
            version: .http2,
            method: .POST,
            url: URI("https://localhost:8080/\(serviceName)/\(methodName)")!,
            headers: headers,
            bodyStorage: .buffer(initialValue: requestData1),
            eventLoop: group.next()
        )

        let response = try service.createUnaryHandler(
            factory: endpoint[DelegateFactory<GRPCTestHandler2, GRPCInterfaceExporter>.self],
            strategy: decodingStrategy,
            defaults: endpoint[DefaultValueStore.self]
        )(request).wait()
        let responseData = try XCTUnwrap(response.bodyStorage.getFullBodyData())
        XCTAssertEqual(responseData, Data(expectedResponseData))
    }

    
    /// Tests request validation for the GRPC exporter.
    /// Should throw for a payload that does not contain data for all required parameters.
    func testUnaryRequestHandlerRequiresAllParameters() throws {
        let testHandler = GRPCTestHandler2()
        
        let endpoint = testHandler.mockEndpoint()
        
        let decodingStrategy = InterfaceExporterLegacyStrategy(exporter).applied(to: endpoint)
        
        let incompleteData: [UInt8] = [0, 0, 0, 0, 8, 10, 6, 77, 111, 114, 105, 116, 122]

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let request = HTTPRequest(
            version: .http2,
            method: .POST,
            url: URI("https://localhost:8080/\(serviceName)/\(methodName)")!,
            headers: headers,
            bodyStorage: .buffer(initialValue: incompleteData),
            eventLoop: group.next()
        )
        

        let handler = service.createUnaryHandler(
            factory: endpoint[DelegateFactory<GRPCTestHandler2, GRPCInterfaceExporter>.self],
            strategy: decodingStrategy,
            defaults: endpoint[DefaultValueStore.self])
        XCTAssertThrowsError(try handler(request).wait())
    }

    
    /// The unary handler should only consider the first message in case
    /// it receives multiple messages in one HTTP frame.
    func testUnaryRequestHandler_2Messages_1Frame() throws {
        let decodingStrategy = InterfaceExporterLegacyStrategy(exporter).applied(to: endpoint)
        
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
        let request = HTTPRequest(
            version: .http2,
            method: .POST,
            url: URI("https://localhost:8080/\(serviceName)/\(methodName)")!,
            headers: headers,
            bodyStorage: .buffer(initialValue: requestData),
            eventLoop: group.next()
        )

        let response = try service.createUnaryHandler(
            factory: endpoint[DelegateFactory<GRPCTestHandler, GRPCInterfaceExporter>.self],
            strategy: decodingStrategy,
            defaults: endpoint[DefaultValueStore.self]
        )(request).wait()
        let responseData = try XCTUnwrap(response.bodyStorage.getFullBodyData())
        XCTAssertEqual(responseData, Data(expectedResponseData))
    }

    
    /// Tests the client-streaming handler for a request with
    /// 1 HTTP frame that contains 1 GRPC messages.
    func testClientStreamingHandlerWith_1Message_1Frame() throws {
        let decodingStrategy = InterfaceExporterLegacyStrategy(exporter).applied(to: endpoint)
        
        // let expectedResponseString = "Hello Moritz"
        let expectedResponseData: [UInt8] =
            [0, 0, 0, 0, 14, 10, 12, 72, 101, 108, 108, 111, 32, 77, 111, 114, 105, 116, 122]

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let request = HTTPRequest(
            version: .http2,
            method: .POST,
            url: URI("https://localhost:8080/\(serviceName)/\(methodName)")!,
            headers: headers,
            bodyStorage: .stream(),
            eventLoop: group.next()
        )
        let stream = try XCTUnwrap(request.bodyStorage.stream)
        
        service.createClientStreamingHandler(
            factory: endpoint[DelegateFactory<GRPCTestHandler, GRPCInterfaceExporter>.self],
            strategy: decodingStrategy,
            defaults: endpoint[DefaultValueStore.self])(request)
            .whenSuccess { response in
                guard let responseData = response.bodyStorage.readNewData() else {
                    XCTFail("Received empty response but expected: \(expectedResponseData)")
                    return
                }
                XCTAssertEqual(responseData, Data(expectedResponseData))
            }

        stream.write(requestData1)
        stream.close()
    }
    

    /// Tests the client-streaming handler for a request with
    /// 1 HTTP frame that contains 2 GRPC messages.
    ///
    /// The handler should only return the response for the last (second)
    /// message contained in the frame.
    func testClientStreamingHandlerWith_2Messages_1Frame() throws {
        let decodingStrategy = InterfaceExporterLegacyStrategy(exporter).applied(to: endpoint)
        
        let requestData: [UInt8] = [
            0, 0, 0, 0, 10, 10, 6, 77, 111, 114, 105, 116, 122, 16, 23,
            0, 0, 0, 0, 9, 10, 5, 66, 101, 114, 110, 100, 16, 23
        ]
        // let expectedResponseString = "Hello Bernd"
        let expectedResponseData: [UInt8] =
            [0, 0, 0, 0, 13, 10, 11, 72, 101, 108, 108, 111, 32, 66, 101, 114, 110, 100]

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let request = HTTPRequest(
            version: .http2,
            method: .POST,
            url: URI("https://localhost:8080/\(serviceName)/\(methodName)")!,
            headers: headers,
            bodyStorage: .stream(),
            eventLoop: group.next()
        )
        let stream = try XCTUnwrap(request.bodyStorage.stream)

        service.createClientStreamingHandler(
            factory: endpoint[DelegateFactory<GRPCTestHandler, GRPCInterfaceExporter>.self],
            strategy: decodingStrategy,
            defaults: endpoint[DefaultValueStore.self]
        )(request)
            .whenSuccess { response in
                guard let responseData = response.bodyStorage.readNewData() else {
                    XCTFail("Received empty response but expected: \(expectedResponseData)")
                    return
                }
                XCTAssertEqual(responseData, Data(expectedResponseData))
            }

        stream.write(requestData)
        stream.close()
    }
    

    /// Tests the client-streaming handler for a request with
    /// 2 HTTP frames that contain 2 GRPC messages.
    /// (each message comes in its own frame)
    ///
    /// The handler should only return the response for the last (second)
    /// message contained in the frame.
    func testClientStreamingHandlerWith_2Messages_2Frames() throws {
        let decodingStrategy = InterfaceExporterLegacyStrategy(exporter).applied(to: endpoint)
        
        // let expectedResponseString = "Hello Bernd"
        let expectedResponseData: [UInt8] =
            [0, 0, 0, 0, 13, 10, 11, 72, 101, 108, 108, 111, 32, 66, 101, 114, 110, 100]

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let request = HTTPRequest(
            version: .http2,
            method: .POST,
            url: URI("https://localhost:8080/\(serviceName)/\(methodName)")!,
            headers: headers,
            bodyStorage:  .stream(),
            eventLoop: group.next()
        )
        let stream = try XCTUnwrap(request.bodyStorage.stream)

        // get first response
        service.createClientStreamingHandler(
            factory: endpoint[DelegateFactory<GRPCTestHandler, GRPCInterfaceExporter>.self],
            strategy: decodingStrategy,
            defaults: endpoint[DefaultValueStore.self]
        )(request)
            .whenSuccess { response in
                guard let responseData = response.bodyStorage.readNewData() else { // TODO or getAllData?
                    XCTFail("Received empty response but expected: \(expectedResponseData)")
                    return
                }
                // Expect empty response data for first GRPC message,
                // because it was not the end yet.
                XCTAssertEqual(responseData, Data(expectedResponseData))
            }

        // write messages individually
        stream.write(requestData1)
        stream.write(requestData2)
        stream.close()
    }
    

    /// Checks whether the returned response for a `.nothing` is indeed empty.
    func testClientStreamingHandlerNothingResponse() throws {
        let handler = GRPCNothingHandler()
        let endpoint = handler.mockEndpoint()
        
        let decodingStrategy = InterfaceExporterLegacyStrategy(exporter).applied(to: endpoint)

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let request = HTTPRequest(
            version: .http2,
            method: .POST,
            url: URI("https://localhost:8080/\(serviceName)/\(methodName)")!,
            headers: headers,
            bodyStorage: .stream(),
            eventLoop: group.next()
        )
        let stream = try XCTUnwrap(request.bodyStorage.stream)

        service.createClientStreamingHandler(
            factory: endpoint[DelegateFactory<GRPCNothingHandler, GRPCInterfaceExporter>.self],
            strategy: decodingStrategy,
            defaults: endpoint[DefaultValueStore.self]
        )(request)
            .whenSuccess { response in
                XCTAssertEqual(
                    response.bodyStorage.readNewData(),
                    Optional(Data()),
                    "Received non-empty response but expected empty response"
                )
            }

        stream.write(requestData1)
        stream.close()
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
        
        let expectedServiceName = "V1Group1Group2Service"

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
        endpoint = handler.mockEndpoint(context: node.export())

        XCTAssertEqual(gRPCServiceName(from: endpoint), serviceName)
    }

    
    func testMethodNameUtility_DefaultName() {
        XCTAssertEqual(gRPCMethodName(from: endpoint), "grpctesthandler")
    }
    

    func testMethodNameUtility_CustomName() {
        let methodName = "testMethod"

        let node = ContextNode()
        node.addContext(GRPCMethodNameContextKey.self, value: methodName, scope: .current)
        endpoint = handler.mockEndpoint(context: node.export())

        XCTAssertEqual(gRPCMethodName(from: endpoint), methodName)
    }
}
