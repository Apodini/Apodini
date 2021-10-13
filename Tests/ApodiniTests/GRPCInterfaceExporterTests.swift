//
//  GRPCInterfaceExporterTests.swift
//  
//
//  Created by Moritz Schüll on 20.12.20.
//

@testable import Apodini
@testable import ApodiniGRPC
import ApodiniExtension
@testable import Vapor
import XCTApodini


private struct GRPCTestHandler: Handler {
    @Parameter("name", .gRPC(.fieldTag(1)))
    var name: String

    func handle() -> String {
        "Hello \(name)"
    }
}


private struct GRPCTestHandler2: Handler {
    @Parameter("name", .gRPC(.fieldTag(1)))
    var name: String
    @Parameter("age", .gRPC(.fieldTag(2)))
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


final class GRPCInterfaceExporterTests: XCTApodiniTest {
    private var gRPCHeaders: HTTPHeaders {
        var headers = HTTPHeaders()
        headers.add(name: .contentType, value: "application/grpc+proto")
        return headers
    }
    
    
    private var gRPCInterfaceExporter: GRPCInterfaceExporter? {
        class GRPCInterfaceExporterVisitor: InterfaceExporterVisitor {
            var gRPCInterfaceExporter: GRPCInterfaceExporter?
            
            
            func visit<I>(exporter: I) where I : InterfaceExporter {
                if let exporter = exporter as? GRPCInterfaceExporter {
                    gRPCInterfaceExporter = exporter
                }
            }
        }
        
        let visitor = GRPCInterfaceExporterVisitor()
        app.interfaceExporters.acceptAll(visitor)
        return visitor.gRPCInterfaceExporter
    }

    // "Moritz"
    fileprivate let moritzData: [UInt8] = [0, 0, 0, 0, 10, 10, 6, 77, 111, 114, 105, 116, 122, 16, 23]
    // "Bernd"
    fileprivate let berndData: [UInt8] = [0, 0, 0, 0, 9, 10, 5, 66, 101, 114, 110, 100, 16, 65]
    // "Hello Moritz"
    fileprivate let helloMoritzData: [UInt8] = [0, 0, 0, 0, 14, 10, 12, 72, 101, 108, 108, 111, 32, 77, 111, 114, 105, 116, 12]
    // "Hello Bernd"
    fileprivate let helloBerndData: [UInt8] = [0, 0, 0, 0, 13, 10, 11, 72, 101, 108, 108, 111, 32, 66, 101, 114, 110, 100]
    fileprivate let serviceName = "TestService"
    fileprivate let methodName = "testMethod"
    
    private struct GRPCWebService<C: Component>: WebService {
        let content: C
        
        
        var configuration: Configuration {
            GRPC()
        }
        
        
        init(_ content: C) {
            self.content = content
        }
        
        init() where C == GRPCTestHandler {
            self.content = GRPCTestHandler()
        }
        
        @available(*, deprecated, message: "A TestWebService must be initialized with a component")
        init() {
            fatalError("A TestWebService must be initialized with a component")
        }
        
        @available(*, deprecated, message: "A TestWebService must be initialized with a component")
        init(from decoder: Decoder) throws {
            fatalError("A TestWebService must be initialized with a component")
        }
    }
    
    
    func endpointAndGRCPExporter<H: Handler>(_ component: H) throws -> (endpoint: Endpoint<H>, exporter: GRPCInterfaceExporter) {
        let endpoint: Endpoint<H> = try XCTCreateMockEndpoint(component, configuration: GRPC())
        let exporter = try app.getInterfaceExporter(GRPCInterfaceExporter.self)
        return (endpoint, exporter)
    }
    
    func testDefaultEndpointNaming() throws {
        let expectedServiceName = "Group1Group2Service"
        
        let endpoint: Endpoint<GRPCTestHandler> = try XCTCreateMockEndpoint(configuration: GRPC()) {
            Group("Group1") {
                Group("Group2") {
                    GRPCTestHandler()
                }
            }
        }
        XCTAssertEqual(gRPCServiceName(from: endpoint), expectedServiceName)
        
        let grpcExporter = try XCTUnwrap(gRPCInterfaceExporter)
        XCTAssertNotNil(grpcExporter.services[expectedServiceName])
    }

    /// Checks that the GRPC exporter considers `.serviceName` context
    /// values for naming services.
    func testExplicitEndpointNaming() throws {
        let expectedServiceName = "MyService"
        
        let endpoint: Endpoint<GRPCTestHandler> = try XCTCreateMockEndpoint(configuration: GRPC()) {
            Group("Group1") {
                Group("Group2") {
                    GRPCTestHandler()
                        .serviceName(expectedServiceName)
                }
            }
        }
        XCTAssertEqual(gRPCServiceName(from: endpoint), expectedServiceName)
        
        let grpcExporter = try XCTUnwrap(gRPCInterfaceExporter)
        XCTAssertNotNil(grpcExporter.services[expectedServiceName])
    }

    func testShouldAcceptMultipleEndpoints() throws {
        let (endpoint, exporter) = try endpointAndGRCPExporter(GRPCTestHandler())
        let service = GRPCService(name: serviceName, using: app, GRPC.ExporterConfiguration())
        let decodingStrategy = InterfaceExporterLegacyStrategy(exporter).applied(to: endpoint)
        
        try service.exposeUnaryEndpoint(name: "endpointName1", endpoint, strategy: decodingStrategy)
        XCTAssertNoThrow(try service.exposeUnaryEndpoint(name: "endpointName2", endpoint, strategy: decodingStrategy))
        XCTAssertNoThrow(try service.exposeClientStreamingEndpoint(name: "endpointName3", endpoint, strategy: decodingStrategy))
    }

    func testShouldNotOverwriteExistingEndpoint() throws {
        let (endpoint, exporter) = try endpointAndGRCPExporter(GRPCTestHandler())
        let service = GRPCService(name: serviceName, using: app, GRPC.ExporterConfiguration())
        let decodingStrategy = InterfaceExporterLegacyStrategy(exporter).applied(to: endpoint)
        
        try service.exposeUnaryEndpoint(name: "endpointName", endpoint, strategy: decodingStrategy)
        XCTAssertThrowsError(try service.exposeUnaryEndpoint(name: "endpointName", endpoint, strategy: decodingStrategy))
        XCTAssertThrowsError(try service.exposeClientStreamingEndpoint(name: "endpointName", endpoint, strategy: decodingStrategy))
    }

    func testShouldRequireContentTypeHeader() throws {
        let (endpoint, exporter) = try endpointAndGRCPExporter(GRPCTestHandler())
        let service = GRPCService(name: serviceName, using: app, GRPC.ExporterConfiguration())
        let decodingStrategy = InterfaceExporterLegacyStrategy(exporter).applied(to: endpoint)
        
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let vaporRequest = Vapor.Request(
            application: app.vapor.app,
            method: .POST,
            url: URI(path: "https://localhost:8080/\(serviceName)/\(methodName)"),
            version: .init(major: 2, minor: 0),
            headers: .init(),
            collectedBody: ByteBuffer(bytes: moritzData),
            remoteAddress: nil,
            logger: app.logger,
            on: group.next()
        )

        var handler = service.createUnaryHandler(
            handler: endpoint.handler,
            strategy: decodingStrategy,
            defaults: endpoint[DefaultValueStore.self]
        )
        XCTAssertThrowsError(try handler(vaporRequest).wait())

        handler = service.createClientStreamingHandler(
            handler: endpoint.handler,
            strategy: decodingStrategy,
            defaults: endpoint[DefaultValueStore.self]
        )
        XCTAssertThrowsError(try handler(vaporRequest).wait())
    }

    func testUnaryRequestHandlerWithOneParamater() throws {
        let (endpoint, exporter) = try endpointAndGRCPExporter(GRPCTestHandler())
        let service = GRPCService(name: serviceName, using: app, GRPC.ExporterConfiguration())
        let decodingStrategy = InterfaceExporterLegacyStrategy(exporter).applied(to: endpoint)

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let vaporRequest = Vapor.Request(
            application: app.vapor.app,
            method: .POST,
            url: URI(path: "https://localhost:8080/\(serviceName)/\(methodName)"),
            version: .init(major: 2, minor: 0),
            headers: gRPCHeaders,
            collectedBody: ByteBuffer(bytes: moritzData),
            remoteAddress: nil,
            logger: app.logger,
            on: group.next()
        )

        let response = try service.createUnaryHandler(
            handler: endpoint.handler,
            strategy: decodingStrategy,
            defaults: endpoint[DefaultValueStore.self]
        )(vaporRequest)
            .wait()
        let responseData: Data = try XCTUnwrap(response.body.data)
        XCTAssertEqual(responseData, Data(helloMoritzData))
    }

    func testUnaryRequestHandlerWithTwoParameters() throws {
        let (endpoint, exporter) = try endpointAndGRCPExporter(GRPCTestHandler2())
        let decodingStrategy = InterfaceExporterLegacyStrategy(exporter).applied(to: endpoint)
        let service = GRPCService(name: serviceName, using: app, GRPC.ExporterConfiguration())

        // let expectedResponseString = "Hello Moritz, you are 23 years old."
        let expectedResponseData: [UInt8] = [
            0, 0, 0, 0, 37,
            10, 35, 72, 101, 108, 108, 111, 32, 77,
            111, 114, 105, 116, 122, 44, 32, 121, 111,
            117, 32, 97, 114, 101, 32, 50, 51, 32, 121,
            101, 97, 114, 115, 32, 111, 108, 100, 46
        ]

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let vaporRequest = Vapor.Request(
            application: app.vapor.app,
            method: .POST,
            url: URI(path: "https://localhost:8080/\(serviceName)/\(methodName)"),
            version: .init(major: 2, minor: 0),
            headers: gRPCHeaders,
            collectedBody: ByteBuffer(bytes: moritzData),
            remoteAddress: nil,
            logger: app.logger,
            on: group.next()
        )

        let response = try service.createUnaryHandler(
            handler: endpoint.handler,
            strategy: decodingStrategy,
            defaults: endpoint[DefaultValueStore.self])(vaporRequest)
            .wait()
        let responseData: Data = try XCTUnwrap(response.body.data)
        XCTAssertEqual(responseData, Data(expectedResponseData))
    }

    /// Tests request validation for the GRPC exporter.
    /// Should throw for a payload that does not contain data for all required parameters.
    func testUnaryRequestHandlerRequiresAllParameters() throws {
        let (endpoint, exporter) = try endpointAndGRCPExporter(GRPCTestHandler2())
        let decodingStrategy = InterfaceExporterLegacyStrategy(exporter).applied(to: endpoint)
        let service = GRPCService(name: serviceName, using: app, GRPC.ExporterConfiguration())
        
        
        let incompleteData: [UInt8] = [0, 0, 0, 0, 8, 10, 6, 77, 111, 114, 105, 116, 122]

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let vaporRequest = Vapor.Request(
            application: app.vapor.app,
            method: .POST,
            url: URI(path: "https://localhost:8080/\(serviceName)/\(methodName)"),
            version: .init(major: 2, minor: 0),
            headers: gRPCHeaders,
            collectedBody: ByteBuffer(bytes: incompleteData),
            remoteAddress: nil,
            logger: app.logger,
            on: group.next()
        )

        let handler = service.createUnaryHandler(
            handler: endpoint.handler,
            strategy: decodingStrategy,
            defaults: endpoint[DefaultValueStore.self]
        )
        
        XCTAssertThrowsError(try handler(vaporRequest).wait())
    }

    /// The unary handler should only consider the first message in case
    /// it receives multiple messages in one HTTP frame.
    func testUnaryRequestHandler_2Messages_1Frame() throws {
        let (endpoint, exporter) = try endpointAndGRCPExporter(GRPCTestHandler())
        let decodingStrategy = InterfaceExporterLegacyStrategy(exporter).applied(to: endpoint)
        let service = GRPCService(name: serviceName, using: app, GRPC.ExporterConfiguration())
        
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let vaporRequest = Vapor.Request(
            application: app.vapor.app,
            method: .POST,
            url: URI(path: "https://localhost:8080/\(serviceName)/\(methodName)"),
            version: .init(major: 2, minor: 0),
            headers: gRPCHeaders,
            collectedBody: ByteBuffer(bytes: moritzData + berndData),
            remoteAddress: nil,
            logger: app.logger,
            on: group.next()
        )

        let response = try service.createUnaryHandler(
            handler: endpoint.handler,
            strategy: decodingStrategy,
            defaults: endpoint[DefaultValueStore.self]
        )(vaporRequest)
            .wait()
        
        let responseData = try XCTUnwrap(response.body.data)
        XCTAssertEqual(responseData, Data(helloMoritzData))
    }

    /// Tests the client-streaming handler for a request with
    /// 1 HTTP frame that contains 1 GRPC messages.
    func testClientStreamingHandlerWith_1Message_1Frame() throws {
        let (endpoint, exporter) = try endpointAndGRCPExporter(GRPCTestHandler())
        let decodingStrategy = InterfaceExporterLegacyStrategy(exporter).applied(to: endpoint)
        let service = GRPCService(name: serviceName, using: app, GRPC.ExporterConfiguration())

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let vaporRequest = Vapor.Request(
            application: app.vapor.app,
            method: .POST,
            url: URI(path: "https://localhost:8080/\(serviceName)/\(methodName)"),
            on: group.next()
        )
        
        vaporRequest.headers = gRPCHeaders
        let stream = Vapor.Request.BodyStream(on: vaporRequest.eventLoop)
        vaporRequest.bodyStorage = .stream(stream)

        service.createClientStreamingHandler(
            handler: endpoint.handler,
            strategy: decodingStrategy,
            defaults: endpoint[DefaultValueStore.self]
        )(vaporRequest)
            .whenSuccess { response in
                guard let responseData = response.body.data else {
                    XCTFail("Received empty response but expected: \(self.helloMoritzData)")
                    return
                }
                XCTAssertEqual(responseData, Data(self.helloMoritzData))
            }

        _ = try stream.write(.buffer(ByteBuffer(bytes: moritzData))).wait()
        _ = try stream.write(.end).wait()
    }

    /// Tests the client-streaming handler for a request with
    /// 1 HTTP frame that contains 2 GRPC messages.
    ///
    /// The handler should only return the response for the last (second)
    /// message contained in the frame.
    func testClientStreamingHandlerWith_2Messages_1Frame() throws {
        let (endpoint, exporter) = try endpointAndGRCPExporter(GRPCTestHandler())
        let decodingStrategy = InterfaceExporterLegacyStrategy(exporter).applied(to: endpoint)
        let service = GRPCService(name: serviceName, using: app, GRPC.ExporterConfiguration())

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let vaporRequest = Vapor.Request(
            application: app.vapor.app,
            method: .POST,
            url: URI(path: "https://localhost:8080/\(serviceName)/\(methodName)"),
            on: group.next()
        )
        vaporRequest.headers = gRPCHeaders
        let stream = Vapor.Request.BodyStream(on: vaporRequest.eventLoop)
        vaporRequest.bodyStorage = .stream(stream)

        service.createClientStreamingHandler(
            handler: endpoint.handler,
            strategy: decodingStrategy,
            defaults: endpoint[DefaultValueStore.self]
        )(vaporRequest)
            .whenSuccess { response in
                guard let responseData = response.body.data else {
                    XCTFail("Received empty response but expected: \(self.helloBerndData)")
                    return
                }
                XCTAssertEqual(responseData, Data(self.helloBerndData))
            }

        _ = try stream.write(.buffer(ByteBuffer(bytes: moritzData + berndData))).wait()
        _ = try stream.write(.end).wait()
    }

    /// Tests the client-streaming handler for a request with
    /// 2 HTTP frames that contain 2 GRPC messages.
    /// (each message comes in its own frame)
    ///
    /// The handler should only return the response for the last (second)
    /// message contained in the frame.
    func testClientStreamingHandlerWith_2Messages_2Frames() throws {
        let (endpoint, exporter) = try endpointAndGRCPExporter(GRPCTestHandler())
        let decodingStrategy = InterfaceExporterLegacyStrategy(exporter).applied(to: endpoint)
        let service = GRPCService(name: serviceName, using: app, GRPC.ExporterConfiguration())
        
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let vaporRequest = Vapor.Request(
            application: app.vapor.app,
            method: .POST,
            url: URI(path: "https://localhost:8080/\(serviceName)/\(methodName)"),
            on: group.next()
        )
        vaporRequest.headers = gRPCHeaders
        let stream = Vapor.Request.BodyStream(on: vaporRequest.eventLoop)
        vaporRequest.bodyStorage = .stream(stream)

        // get first response
        service.createClientStreamingHandler(
            handler: endpoint.handler,
            strategy: decodingStrategy,
            defaults: endpoint[DefaultValueStore.self]
        )(vaporRequest)
            .whenSuccess { response in
                guard let responseData = response.body.data else {
                    XCTFail("Received empty response but expected: \(self.helloBerndData)")
                    return
                }
                // Expect empty response data for first GRPC message,
                // because it was not the end yet.
                XCTAssertEqual(responseData, Data(self.helloBerndData))
            }

        // write messages individually
        _ = try stream.write(.buffer(ByteBuffer(bytes: moritzData))).wait()
        _ = try stream.write(.buffer(ByteBuffer(bytes: berndData))).wait()
        _ = try stream.write(.end).wait()
    }

    /// Checks whether the returned response for a `.nothing` is indeed empty.
    func testClientStreamingHandlerNothingResponse() throws {
        let (endpoint, exporter) = try endpointAndGRCPExporter(GRPCTestHandler())
        let decodingStrategy = InterfaceExporterLegacyStrategy(exporter).applied(to: endpoint)
        let service = GRPCService(name: serviceName, using: app, GRPC.ExporterConfiguration())

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let vaporRequest = Vapor.Request(
            application: app.vapor.app,
            method: .POST,
            url: URI(path: "https://localhost:8080/\(serviceName)/\(methodName)"),
            on: group.next()
        )
        vaporRequest.headers = gRPCHeaders
        let stream = Vapor.Request.BodyStream(on: vaporRequest.eventLoop)
        vaporRequest.bodyStorage = .stream(stream)

        service.createClientStreamingHandler(
            handler: endpoint.handler,
            strategy: decodingStrategy,
            defaults: endpoint[DefaultValueStore.self]
        )(vaporRequest)
            .whenSuccess { response in
                XCTAssertEqual(
                    response.body.data,
                    Optional(Data()),
                    "Received non-empty response but expected empty response"
                )
            }

        _ = try stream.write(.buffer(ByteBuffer(bytes: moritzData))).wait()
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

    func testServiceNameUtility_CustomName() throws {
        let serviceName = "TestService"
        
        let (endpoint, _) = try endpointAndGRCPExporter(GRPCTestHandler().serviceName(serviceName))
        XCTAssertEqual(gRPCServiceName(from: endpoint), serviceName)
    }

    func testMethodNameUtility_DefaultName() throws {
        let (endpoint, _) = try endpointAndGRCPExporter(GRPCTestHandler())
        XCTAssertEqual(gRPCMethodName(from: endpoint), "grpctesthandler")
    }

    func testMethodNameUtility_CustomName() throws {
        let methodName = "testMethod"
        
        let (endpoint, _) = try endpointAndGRCPExporter(GRPCTestHandler().rpcName(methodName))
        XCTAssertEqual(gRPCMethodName(from: endpoint), methodName)
    }
}
