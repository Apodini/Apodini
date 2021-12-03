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
@testable import ProtobufferCoding
import XCTApodini
import XCTApodiniNetworking
import ApodiniUtils



private struct GRPCInterfaceExporterTestError: Swift.Error {
    let message: String
}


/// A proto value wrapped in a message, assigned to a `value` field.
/// Useful for interacting w/ handlers that have a wrapped input/output value.
/// - Note: The handler's wrapped property doesn't actually have to be called value
///         (in reality they're usually named after the `@Property` they were mapped from),
///         the only important thing is that the field number is also 1.
///         (Which should be the case when using the default implementation.)
private struct WrappedProtoValue<T: Codable>: Codable {
    let value: T
}


class GRPCInterfaceExporterTests: XCTApodiniTest {
    static func grpcurlExecutableUrl() -> URL? {
        if let url = ChildProcess.findExecutable(named: "grpcurl", additionalSearchPaths: ["/usr/local/bin/"]) {
            return url
        } else {
            // grpcurl is not in the PATH, but it might be somewhere else if it was downloaded by the test runner
            //throw GRPCInterfaceExporterTestError(message: "Unable to find grpcurl")
            return nil
        }
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        XCTAssert(!app.httpServer.isRunning)
    }
    
    
    
    struct TestGRPCExporterCollection: ConfigurationCollection {
        var configuration: Configuration {
            HTTPConfiguration(
                bindAddress: .interface("localhost", port: 50051),
                tlsConfigurationBuilder: .init(
                    certificatePath: "/Users/lukas/Documents/apodini certs/localhost.cer.pem",
                    keyPath: "/Users/lukas/Documents/apodini certs/localhost.key.pem"
                )
            )
            GRPC(packageName: "de.lukaskollmer", serviceName: "TestWebService")
        }
    }
    
    
    func testReflection() throws {
        struct WebService: Apodini.WebService {
            var content: some Component {
                Text("Hello World")
                    .gRPCMethodName("Root")
                Group("team") {
                    Text("Alice and Bob")
                        .gRPCMethodName("GetTeam")
                }
                Group("api") {
                    Text("").gRPCMethodName("GetPosts")
                    Text("").gRPCMethodName("AddPost")
                    Text("").gRPCMethodName("DeletePost")
                }.gRPCServiceName("API")
            }
        }
        TestGRPCExporterCollection().configuration.configure(app)
        let visitor = SyntaxTreeVisitor(modelBuilder: SemanticModelBuilder(app))
        WebService().accept(visitor)
        visitor.finishParsing()
        try app.start()
        
        guard let grpcurlBin = Self.grpcurlExecutableUrl() else {
            throw XCTSkip("Unable to find grpcurl")
        }
        func runGRPCurl(_ input: [String]) throws -> (exitCode: Int32, output: String) {
            let grpcurl = ChildProcess(
                executableUrl: grpcurlBin,
                arguments: ["-insecure", "localhost:50051"] + input,
                workingDirectory: nil,
                captureOutput: true,
                redirectStderrToStdout: true,
                launchInCurrentProcessGroup: false,
                environment: [:],
                inheritsParentEnvironment: true
            )
            let TI = try grpcurl.launchSync()
            return (TI.exitCode, try grpcurl.readStdoutToEnd())
        }
        
        
        let listServices = try runGRPCurl(["list"])
        XCTAssertEqual(listServices.exitCode, 0, "grpcurl list services request failed. output: \(listServices.output)")
        XCTAssert(listServices.output.trimmingLeadingAndTrailingWhitespace().components(separatedBy: "\n").compareIgnoringOrder([
            "de.lukaskollmer.API",
            "de.lukaskollmer.TestWebService",
            "grpc.reflection.v1alpha.ServerReflection"
        ]))
        
        let describeServices = try runGRPCurl(["describe"])
        XCTAssertEqual(describeServices.exitCode, 0, "grpcurl describe services request failed. output: \(describeServices.output)")
        // The order of the response is not guaranteed, so we have to check all possible outputs
        let responseParts: [String] = [
            """
            de.lukaskollmer.TestWebService is a service:
            service TestWebService {
              rpc GetTeam ( .de.lukaskollmer.EmptyMessage ) returns ( .de.lukaskollmer.Text___Response );
              rpc Root ( .de.lukaskollmer.EmptyMessage ) returns ( .de.lukaskollmer.Text___Response );
            }
            """,
            """
            grpc.reflection.v1alpha.ServerReflection is a service:
            service ServerReflection {
              rpc ServerReflectionInfo ( stream .grpc.reflection.v1alpha.ServerReflectionRequest ) returns ( stream .grpc.reflection.v1alpha.ServerReflectionResponse );
            }
            """,
            """
            de.lukaskollmer.API is a service:
            service API {
              rpc AddPost ( .de.lukaskollmer.EmptyMessage ) returns ( .de.lukaskollmer.Text___Response );
              rpc DeletePost ( .de.lukaskollmer.EmptyMessage ) returns ( .de.lukaskollmer.Text___Response );
              rpc GetPosts ( .de.lukaskollmer.EmptyMessage ) returns ( .de.lukaskollmer.Text___Response );
            }
            """
        ]
        XCTAssert(responseParts.allSatisfy { describeServices.output.contains($0) })
        XCTAssertEqual(describeServices.output.split(string: " is a service:").count - 1, responseParts.count)
    }
    
    
    
    func testUnaryEndpoint() throws {
        struct BlockBasedHandler<T: Apodini.ResponseTransformable /* or Content? */>: Handler {
            let imp: () async throws -> T
            func handle() async throws -> T {
                try await imp()
            }
        }
        
        struct WebService: Apodini.WebService {
            var content: some Component {
                Text("Hello World")
                    .gRPCMethodName("Root")
                Group("team") {
                    Text("Alice and Bob")
                        .gRPCMethodName("GetTeam")
                }
                Group("api") {
                    Text("A").gRPCMethodName("GetPost")
                    Text("B").gRPCMethodName("AddPost")
                    Text("C").gRPCMethodName("DeletePost")
                    BlockBasedHandler<[String]> { ["", "a", "b", "c", "d"] }.gRPCMethodName("ListPosts")
                    BlockBasedHandler<[Int]> { [0, 1, 2, 3, 4, -52] }.gRPCMethodName("ListIDs")
                    BlockBasedHandler<Int> { 1 }.gRPCMethodName("GetAnInt")
                }.gRPCServiceName("API")
            }
        }
        
        TestGRPCExporterCollection().configuration.configure(app)
        let visitor = SyntaxTreeVisitor(modelBuilder: SemanticModelBuilder(app))
        WebService().accept(visitor)
        visitor.finishParsing()
        try app.start()
        
        let response1 = try makeTestRequestUnary(method: "de.lukaskollmer.TestWebService.Root", EmptyMessage(), outputType: WrappedProtoValue<String>.self)
        XCTAssertEqual(response1.value, "Hello World")
        
        let response2 = try makeTestRequestUnary(method: "de.lukaskollmer.TestWebService.GetTeam", EmptyMessage(), outputType: WrappedProtoValue<String>.self)
        XCTAssertEqual(response2.value, "Alice and Bob")
        
        let response3 = try makeTestRequestUnary(method: "de.lukaskollmer.API.GetPost", EmptyMessage(), outputType: WrappedProtoValue<String>.self)
        XCTAssertEqual(response3.value, "A")
        
        let response4 = try makeTestRequestUnary(method: "de.lukaskollmer.API.AddPost", EmptyMessage(), outputType: WrappedProtoValue<String>.self)
        XCTAssertEqual(response4.value, "B")
        
        let response5 = try makeTestRequestUnary(method: "de.lukaskollmer.API.DeletePost", EmptyMessage(), outputType: WrappedProtoValue<String>.self)
        XCTAssertEqual(response5.value, "C")
        
        
        XCTAssertEqual(
            try makeTestRequestUnary(method: "de.lukaskollmer.API.ListPosts", EmptyMessage(), outputType: WrappedProtoValue<[String]>.self).value,
            ["", "a", "b", "c", "d"]
        )
        
        do {
            let response = try makeTestRequestUnary(method: "de.lukaskollmer.API.ListIDs", EmptyMessage())
            let object = try JSONSerialization.jsonObject(with: ByteBuffer(string: response), options: [])
            // We have to compare against a `[String: [String]]` here, despite the actual return type being `[String: [Int]]`,
            // the reason being that grpcurl quotes integer values, thus effectively turning them into strings.
            // (No, we're not encoding using the wrong wire type.)
            // See also: https://github.com/fullstorydev/grpcurl/issues/272
            let dict = try XCTUnwrap(object as? Dictionary<String, [String]>)
            XCTAssertEqual(dict, ["value": ["0", "1", "2", "3", "4", "-52"]])
        }
    }
    
    
    
    
}


// MARK: gRPC test request stuff

extension GRPCInterfaceExporterTests {
//    /// A response for a test request
//    struct XCTGRPCResponse {
//        let headers:
//    }
    
    /// Sends a single request to the specified unary method.
    /// - returns: the response object, decoded from the response JSON string as the specified type
    private func makeTestRequestUnary<In: Encodable, Out: Decodable>(
        serverAddress: String = "localhost", port: Int = 50051,
        method: String, _ input: In, outputType: Out.Type
    ) throws -> Out {
        let response: String = try makeTestRequestUnary(serverAddress: serverAddress, port: port, method: method, input)
        // grpcurl only supports JSON output, which means we sadly can't decode the actual proto bytes here :/
        return try JSONDecoder().decode(Out.self, from: ByteBuffer(string: response))
    }
    
    
    /// Sends a single request to the specified unary method.
    /// - returns: a JSON string representing the response to the request
    private func makeTestRequestUnary<In: Encodable>(
        serverAddress: String = "localhost", port: Int = 50051,
        method: String, _ input: In
    ) throws -> String {
        guard let grpcurlBin = Self.grpcurlExecutableUrl() else {
            throw XCTSkip("Unable to find grpcurl")
        }
        let grpcurl = ChildProcess(
            executableUrl: grpcurlBin,
            arguments: ["-insecure", "-emit-defaults", "localhost:50051", method],
            workingDirectory: nil,
            captureOutput: true,
            redirectStderrToStdout: true,
            launchInCurrentProcessGroup: false,
            environment: [:],
            inheritsParentEnvironment: true
        )
        let TI = try grpcurl.launchSync()
        let output = try grpcurl.readStdoutToEnd()
        print("\n\n\n\nOUTPUT: \(output)\n\n\n\n")
        XCTAssertEqual(TI.exitCode, 0, "grpcurl unexpectedly exited w/ non-zero exit code \(TI.exitCode). (output: \(output))")
        return output
//        // grpcurl only supports JSON output, which means we sadly can't decode the actual proto bytes here :/
//        let decoder = JSONDecoder()
//        return try JSONDecoder().decode(Out.self, from: ByteBuffer(string: output))
    }
}


















//import XCTest
//@testable import Apodini
//@testable import ApodiniGRPC_old
//import ApodiniExtension
//import XCTApodiniNetworking
//
//
//private struct GRPCTestHandler: Handler {
//    @Parameter("name",
//               .gRPC(.fieldTag(1)))
//    var name: String
//
//    func handle() -> String {
//        "Hello \(name)"
//    }
//}
//
//private struct GRPCTestHandler2: Handler {
//    @Parameter("name",
//               .gRPC(.fieldTag(1)))
//    var name: String
//    @Parameter("age",
//               .gRPC(.fieldTag(2)))
//    var age: Int32
//
//    func handle() -> String {
//        "Hello \(name), you are \(age) years old."
//    }
//}
//
//private struct GRPCNothingHandler: Handler {
//    func handle() -> Apodini.Response<Int32> {
//        .nothing
//    }
//}
//
//
//final class GRPCInterfaceExporterTests: ApodiniTests {
//    // swiftlint:disable implicitly_unwrapped_optional
//    fileprivate var exporterConfiguration: GRPC.ExporterConfiguration!
//    fileprivate var service: GRPCService!
//    fileprivate var handler: GRPCTestHandler!
//    fileprivate var endpoint: Endpoint<GRPCTestHandler>!
//    fileprivate var rendpoint: RelationshipEndpoint<GRPCTestHandler>!
//    fileprivate var exporter: GRPCInterfaceExporter!
//    fileprivate var headers: HTTPHeaders!
//    // swiftlint:enable implicitly_unwrapped_optional
//
//    fileprivate let serviceName = "TestService"
//    fileprivate let methodName = "testMethod"
//    fileprivate let requestData1: [UInt8] = [0, 0, 0, 0, 10, 10, 6, 77, 111, 114, 105, 116, 122, 16, 23]
//    fileprivate let requestData2: [UInt8] = [0, 0, 0, 0, 9, 10, 5, 66, 101, 114, 110, 100, 16, 65]
//
//    override func setUpWithError() throws {
//        try super.setUpWithError()
//        exporterConfiguration = GRPC.ExporterConfiguration()
//        service = GRPCService(name: serviceName, using: app, exporterConfiguration)
//        handler = GRPCTestHandler()
//        (endpoint, rendpoint) = handler.mockRelationshipEndpoint()
//        exporter = GRPCInterfaceExporter(app)
//        headers = HTTPHeaders()
//        headers[.contentType] = .gRPC(.proto)
//    }
//
//    
//    func testDefaultEndpointNaming() throws {
//        struct TestWebService: WebService {
//            var content: some Component {
//                Group("Group1") {
//                    Group("Group2") {
//                        GRPCTestHandler()
//                    }
//                }
//            }
//        }
//        
//        let expectedServiceName = "V1Group1Group2Service"
//
//        let modelBuilder = SemanticModelBuilder(app)
//        let visitor = SyntaxTreeVisitor(modelBuilder: modelBuilder)
//        TestWebService().accept(visitor)
//        visitor.finishParsing()
//        
//        let endpoint = try XCTUnwrap(modelBuilder.collectedEndpoints.first as? Endpoint<GRPCTestHandler>)
//
//        let exporter = GRPCInterfaceExporter(app)
//        exporter.export(endpoint)
//        print(exporter.services)
//        XCTAssertNotNil(exporter.services[expectedServiceName])
//    }
//
//    
//    /// Checks that the GRPC exporter considers `.serviceName` context
//    /// values for naming services.
//    func testExplicitEndpointNaming() throws {
//        let expectedServiceName = "MyService"
//
//        let webService = RelationshipWebServiceModel()
//
//        let handler = GRPCTestHandler()
//        let node = ContextNode()
//        node.addContext(GRPCServiceNameContextKey.self, value: expectedServiceName, scope: .current)
//        var (endpoint, rendpoint) = handler.mockRelationshipEndpoint(context: node.export())
//
//        webService.addEndpoint(&rendpoint, at: ["Group1", "Group2"])
//
//        let exporter = GRPCInterfaceExporter(app)
//        exporter.export(endpoint)
//
//        XCTAssertNotNil(exporter.services[expectedServiceName])
//    }
//
//    
//    func testShouldAcceptMultipleEndpoints() throws {
//        let decodingStrategy = InterfaceExporterLegacyStrategy(exporter).applied(to: endpoint)
//        
//        try service.exposeUnaryEndpoint(name: "endpointName1", endpoint, strategy: decodingStrategy)
//        XCTAssertNoThrow(try service.exposeUnaryEndpoint(name: "endpointName2", endpoint, strategy: decodingStrategy))
//        XCTAssertNoThrow(try service.exposeClientStreamingEndpoint(name: "endpointName3", endpoint, strategy: decodingStrategy))
//    }
//
//    
//    func testShouldNotOverwriteExistingEndpoint() throws {
//        let decodingStrategy = InterfaceExporterLegacyStrategy(exporter).applied(to: endpoint)
//        
//        try service.exposeUnaryEndpoint(name: "endpointName", endpoint, strategy: decodingStrategy)
//        XCTAssertThrowsError(try service.exposeUnaryEndpoint(name: "endpointName", endpoint, strategy: decodingStrategy))
//        XCTAssertThrowsError(try service.exposeClientStreamingEndpoint(name: "endpointName", endpoint, strategy: decodingStrategy))
//    }
//
//    
//    func testShouldRequireContentTypeHeader() throws {
//        let decodingStrategy = InterfaceExporterLegacyStrategy(exporter).applied(to: endpoint)
//        
//        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
//        let request = HTTPRequest(
//            version: .http2,
//            method: .POST,
//            url: URI("https://localhost:8080/\(serviceName)/\(methodName)")!,
//            headers: [:],
//            bodyStorage: .buffer(initialValue: requestData1),
//            eventLoop: group.next()
//        )
//
//        var handler = service.createUnaryHandler(
//            factory: endpoint[DelegateFactory<GRPCTestHandler, GRPCInterfaceExporter>.self],
//            strategy: decodingStrategy,
//            defaults: endpoint[DefaultValueStore.self]
//        )
//        XCTAssertThrowsError(try handler(request).wait())
//
//        handler = service.createClientStreamingHandler(
//            factory: endpoint[DelegateFactory<GRPCTestHandler, GRPCInterfaceExporter>.self],
//            strategy: decodingStrategy,
//            defaults: endpoint[DefaultValueStore.self])
//        XCTAssertThrowsError(try handler(request).wait())
//    }
//
//    
//    func testUnaryRequestHandlerWithOneParamater() throws {
//        let decodingStrategy = InterfaceExporterLegacyStrategy(exporter).applied(to: endpoint)
//        
//        // let expectedResponseString = "Hello Moritz"
//        let expectedResponseData: [UInt8] =
//            [0, 0, 0, 0, 14, 10, 12, 72, 101, 108, 108, 111, 32, 77, 111, 114, 105, 116, 122]
//
//        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
//        let request = HTTPRequest(
//            version: .http2,
//            method: .POST,
//            url: URI("https://localhost:8080/\(serviceName)/\(methodName)")!,
//            headers: headers,
//            bodyStorage: .buffer(initialValue: requestData1),
//            eventLoop: group.next()
//        )
//
//        let response = try service.createUnaryHandler(
//            factory: endpoint[DelegateFactory<GRPCTestHandler, GRPCInterfaceExporter>.self],
//            strategy: decodingStrategy,
//            defaults: endpoint[DefaultValueStore.self]
//        )(request).wait() // swiftlint:disable:this multiline_function_chains
//        let responseData = try XCTUnwrap(response.bodyStorage.getFullBodyData())
//        XCTAssertEqual(responseData, Data(expectedResponseData))
//    }
//
//    
//    func testUnaryRequestHandlerWithTwoParameters() throws {
//        let handler = GRPCTestHandler2()
//        let endpoint = handler.mockEndpoint()
//        
//        let decodingStrategy = InterfaceExporterLegacyStrategy(exporter).applied(to: endpoint)
//
//        // let expectedResponseString = "Hello Moritz, you are 23 years old."
//        let expectedResponseData: [UInt8] = [
//            0, 0, 0, 0, 37,
//            10, 35, 72, 101, 108, 108, 111, 32, 77,
//            111, 114, 105, 116, 122, 44, 32, 121, 111,
//            117, 32, 97, 114, 101, 32, 50, 51, 32, 121,
//            101, 97, 114, 115, 32, 111, 108, 100, 46
//        ]
//
//        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
//        let request = HTTPRequest(
//            version: .http2,
//            method: .POST,
//            url: URI("https://localhost:8080/\(serviceName)/\(methodName)")!,
//            headers: headers,
//            bodyStorage: .buffer(initialValue: requestData1),
//            eventLoop: group.next()
//        )
//
//        let response = try service.createUnaryHandler(
//            factory: endpoint[DelegateFactory<GRPCTestHandler2, GRPCInterfaceExporter>.self],
//            strategy: decodingStrategy,
//            defaults: endpoint[DefaultValueStore.self]
//        )(request).wait() // swiftlint:disable:this multiline_function_chains
//        let responseData = try XCTUnwrap(response.bodyStorage.getFullBodyData())
//        XCTAssertEqual(responseData, Data(expectedResponseData))
//    }
//
//    
//    /// Tests request validation for the GRPC exporter.
//    /// Should throw for a payload that does not contain data for all required parameters.
//    func testUnaryRequestHandlerRequiresAllParameters() throws {
//        let testHandler = GRPCTestHandler2()
//        
//        let endpoint = testHandler.mockEndpoint()
//        
//        let decodingStrategy = InterfaceExporterLegacyStrategy(exporter).applied(to: endpoint)
//        
//        let incompleteData: [UInt8] = [0, 0, 0, 0, 8, 10, 6, 77, 111, 114, 105, 116, 122]
//
//        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
//        let request = HTTPRequest(
//            version: .http2,
//            method: .POST,
//            url: URI("https://localhost:8080/\(serviceName)/\(methodName)")!,
//            headers: headers,
//            bodyStorage: .buffer(initialValue: incompleteData),
//            eventLoop: group.next()
//        )
//        
//
//        let handler = service.createUnaryHandler(
//            factory: endpoint[DelegateFactory<GRPCTestHandler2, GRPCInterfaceExporter>.self],
//            strategy: decodingStrategy,
//            defaults: endpoint[DefaultValueStore.self])
//        XCTAssertThrowsError(try handler(request).wait())
//    }
//
//    
//    /// The unary handler should only consider the first message in case
//    /// it receives multiple messages in one HTTP frame.
//    func testUnaryRequestHandler_2Messages_1Frame() throws {
//        let decodingStrategy = InterfaceExporterLegacyStrategy(exporter).applied(to: endpoint)
//        
//        // First one is "Moritz", second one is "Bernd".
//        // Only the first should be considered.
//        let requestData: [UInt8] = [
//            0, 0, 0, 0, 10, 10, 6, 77, 111, 114, 105, 116, 122, 16, 23,
//            0, 0, 0, 0, 9, 10, 5, 66, 101, 114, 110, 100, 16, 23
//        ]
//
//        // let expectedResponseString = "Hello Moritz"
//        let expectedResponseData: [UInt8] =
//            [0, 0, 0, 0, 14, 10, 12, 72, 101, 108, 108, 111, 32, 77, 111, 114, 105, 116, 122]
//
//        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
//        let request = HTTPRequest(
//            version: .http2,
//            method: .POST,
//            url: URI("https://localhost:8080/\(serviceName)/\(methodName)")!,
//            headers: headers,
//            bodyStorage: .buffer(initialValue: requestData),
//            eventLoop: group.next()
//        )
//
//        let response = try service.createUnaryHandler(
//            factory: endpoint[DelegateFactory<GRPCTestHandler, GRPCInterfaceExporter>.self],
//            strategy: decodingStrategy,
//            defaults: endpoint[DefaultValueStore.self]
//        )(request).wait() // swiftlint:disable:this multiline_function_chains
//        let responseData = try XCTUnwrap(response.bodyStorage.getFullBodyData())
//        XCTAssertEqual(responseData, Data(expectedResponseData))
//    }
//
//    
//    /// Tests the client-streaming handler for a request with
//    /// 1 HTTP frame that contains 1 GRPC messages.
//    func testClientStreamingHandlerWith_1Message_1Frame() throws {
//        let decodingStrategy = InterfaceExporterLegacyStrategy(exporter).applied(to: endpoint)
//        
//        // let expectedResponseString = "Hello Moritz"
//        let expectedResponseData: [UInt8] =
//            [0, 0, 0, 0, 14, 10, 12, 72, 101, 108, 108, 111, 32, 77, 111, 114, 105, 116, 122]
//
//        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
//        let request = HTTPRequest(
//            version: .http2,
//            method: .POST,
//            url: URI("https://localhost:8080/\(serviceName)/\(methodName)")!,
//            headers: headers,
//            bodyStorage: .stream(),
//            eventLoop: group.next()
//        )
//        let stream = try XCTUnwrap(request.bodyStorage.stream)
//        
//        service.createClientStreamingHandler(
//            factory: endpoint[DelegateFactory<GRPCTestHandler, GRPCInterfaceExporter>.self],
//            strategy: decodingStrategy,
//            defaults: endpoint[DefaultValueStore.self])(request)
//            .whenSuccess { response in
//                guard let responseData = response.bodyStorage.readNewData() else {
//                    XCTFail("Received empty response but expected: \(expectedResponseData)")
//                    return
//                }
//                XCTAssertEqual(responseData, Data(expectedResponseData))
//            }
//
//        stream.write(requestData1)
//        stream.close()
//    }
//    
//
//    /// Tests the client-streaming handler for a request with
//    /// 1 HTTP frame that contains 2 GRPC messages.
//    ///
//    /// The handler should only return the response for the last (second)
//    /// message contained in the frame.
//    func testClientStreamingHandlerWith_2Messages_1Frame() throws {
//        let decodingStrategy = InterfaceExporterLegacyStrategy(exporter).applied(to: endpoint)
//        
//        let requestData: [UInt8] = [
//            0, 0, 0, 0, 10, 10, 6, 77, 111, 114, 105, 116, 122, 16, 23,
//            0, 0, 0, 0, 9, 10, 5, 66, 101, 114, 110, 100, 16, 23
//        ]
//        // let expectedResponseString = "Hello Bernd"
//        let expectedResponseData: [UInt8] =
//            [0, 0, 0, 0, 13, 10, 11, 72, 101, 108, 108, 111, 32, 66, 101, 114, 110, 100]
//
//        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
//        let request = HTTPRequest(
//            version: .http2,
//            method: .POST,
//            url: URI("https://localhost:8080/\(serviceName)/\(methodName)")!,
//            headers: headers,
//            bodyStorage: .stream(),
//            eventLoop: group.next()
//        )
//        let stream = try XCTUnwrap(request.bodyStorage.stream)
//
//        service.createClientStreamingHandler(
//            factory: endpoint[DelegateFactory<GRPCTestHandler, GRPCInterfaceExporter>.self],
//            strategy: decodingStrategy,
//            defaults: endpoint[DefaultValueStore.self]
//        )(request)
//            .whenSuccess { response in
//                guard let responseData = response.bodyStorage.readNewData() else {
//                    XCTFail("Received empty response but expected: \(expectedResponseData)")
//                    return
//                }
//                XCTAssertEqual(responseData, Data(expectedResponseData))
//            }
//
//        stream.write(requestData)
//        stream.close()
//    }
//    
//
//    /// Tests the client-streaming handler for a request with
//    /// 2 HTTP frames that contain 2 GRPC messages.
//    /// (each message comes in its own frame)
//    ///
//    /// The handler should only return the response for the last (second)
//    /// message contained in the frame.
//    func testClientStreamingHandlerWith_2Messages_2Frames() throws {
//        let decodingStrategy = InterfaceExporterLegacyStrategy(exporter).applied(to: endpoint)
//        
//        // let expectedResponseString = "Hello Bernd"
//        let expectedResponseData: [UInt8] =
//            [0, 0, 0, 0, 13, 10, 11, 72, 101, 108, 108, 111, 32, 66, 101, 114, 110, 100]
//
//        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
//        let request = HTTPRequest(
//            version: .http2,
//            method: .POST,
//            url: URI("https://localhost:8080/\(serviceName)/\(methodName)")!,
//            headers: headers,
//            bodyStorage: .stream(),
//            eventLoop: group.next()
//        )
//        let stream = try XCTUnwrap(request.bodyStorage.stream)
//
//        // get first response
//        service.createClientStreamingHandler(
//            factory: endpoint[DelegateFactory<GRPCTestHandler, GRPCInterfaceExporter>.self],
//            strategy: decodingStrategy,
//            defaults: endpoint[DefaultValueStore.self]
//        )(request)
//            .whenSuccess { response in
//                guard let responseData = response.bodyStorage.readNewData() else {
//                    XCTFail("Received empty response but expected: \(expectedResponseData)")
//                    return
//                }
//                // Expect empty response data for first GRPC message,
//                // because it was not the end yet.
//                XCTAssertEqual(responseData, Data(expectedResponseData))
//            }
//
//        // write messages individually
//        stream.write(requestData1)
//        stream.write(requestData2)
//        stream.close()
//    }
//    
//
//    /// Checks whether the returned response for a `.nothing` is indeed empty.
//    func testClientStreamingHandlerNothingResponse() throws {
//        let handler = GRPCNothingHandler()
//        let endpoint = handler.mockEndpoint()
//        
//        let decodingStrategy = InterfaceExporterLegacyStrategy(exporter).applied(to: endpoint)
//
//        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
//        let request = HTTPRequest(
//            version: .http2,
//            method: .POST,
//            url: URI("https://localhost:8080/\(serviceName)/\(methodName)")!,
//            headers: headers,
//            bodyStorage: .stream(),
//            eventLoop: group.next()
//        )
//        let stream = try XCTUnwrap(request.bodyStorage.stream)
//
//        service.createClientStreamingHandler(
//            factory: endpoint[DelegateFactory<GRPCNothingHandler, GRPCInterfaceExporter>.self],
//            strategy: decodingStrategy,
//            defaults: endpoint[DefaultValueStore.self]
//        )(request)
//            .whenSuccess { response in
//                XCTAssertEqual(
//                    response.bodyStorage.readNewData(),
//                    Optional(Data()),
//                    "Received non-empty response but expected empty response"
//                )
//            }
//
//        stream.write(requestData1)
//        stream.close()
//    }
//
//    func testServiceNameUtility_DefaultName() throws {
//        struct TestWebService: WebService {
//            var content: some Component {
//                Group("Group1") {
//                    Group("Group2") {
//                        GRPCTestHandler()
//                    }
//                }
//            }
//        }
//        
//        let expectedServiceName = "V1Group1Group2Service"
//
//        let modelBuilder = SemanticModelBuilder(app)
//        let visitor = SyntaxTreeVisitor(modelBuilder: modelBuilder)
//        TestWebService().accept(visitor)
//        visitor.finishParsing()
//        
//        let endpoint = try XCTUnwrap(modelBuilder.collectedEndpoints.first as? Endpoint<GRPCTestHandler>)
//        XCTAssertEqual(gRPCServiceName(from: endpoint), expectedServiceName)
//    }
//
//    
//    func testServiceNameUtility_CustomName() {
//        let serviceName = "TestService"
//
//        let node = ContextNode()
//        node.addContext(GRPCServiceNameContextKey.self, value: serviceName, scope: .current)
//        endpoint = handler.mockEndpoint(context: node.export())
//
//        XCTAssertEqual(gRPCServiceName(from: endpoint), serviceName)
//    }
//
//    
//    func testMethodNameUtility_DefaultName() {
//        XCTAssertEqual(gRPCMethodName(from: endpoint), "grpctesthandler")
//    }
//    
//
//    func testMethodNameUtility_CustomName() {
//        let methodName = "testMethod"
//
//        let node = ContextNode()
//        node.addContext(GRPCMethodNameContextKey.self, value: methodName, scope: .current)
//        endpoint = handler.mockEndpoint(context: node.export())
//
//        XCTAssertEqual(gRPCMethodName(from: endpoint), methodName)
//    }
//}
