//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable line_length

import XCTest
@testable import Apodini
@testable import ApodiniGRPC
@testable import ProtobufferCoding
import XCTApodini
import XCTApodiniNetworking
import ApodiniUtils
import NIO
import XCTUtils


// MARK: Helper Types

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

extension WrappedProtoValue: Equatable where T: Equatable {}

struct BlockBasedHandler<T: Apodini.ResponseTransformable /* or Content? */>: Handler {
    let imp: () async throws -> T
    func handle() async throws -> T {
        try await imp()
    }
}


extension Application {
    func firstInterfaceExporter<IE: InterfaceExporter>(ofType _: IE.Type) -> IE? {
        for element in self.interfaceExporters {
            if let exporter = element.typeErasedInterfaceExporter as? IE {
                return exporter
            }
        }
        return nil
    }
}


// MARK: Tests

class GRPCInterfaceExporterTests: XCTApodiniTest {
    static func grpcurlExecutableUrl() -> URL? {
        if let url = ChildProcess.findExecutable(
            named: "grpcurl",
            additionalSearchPaths: ["/usr/local/bin/", "/opt/homebrew/bin/"]
        ) {
            return url
        } else {
            // grpcurl is not in the PATH, but it might be somewhere else if it was downloaded by the test runner
            //throw GRPCInterfaceExporterTestError(message: "Unable to find grpcurl")
            return nil
        }
    }
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        try skipIfRunningInXcode()
        // ^^ For reasons I cannot understand, the gRPC tests will work fine when run from the terminal,
        // but always hang (waiting for the grpcurl child process, which itself is waiting for something else)
        // when run in Xcode. This probably is caused by the attached debugger.
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
                    //certificatePath: "/Users/lukas/Documents/apodini certs/localhost.cer.pem",
                    //keyPath: "/Users/lukas/Documents/apodini certs/localhost.key.pem"
                    certificatePath: try! XCTUnwrap(Bundle.module.url(forResource: "apodini_https_cert_localhost.cer", withExtension: "pem")).path,
                    keyPath: try! XCTUnwrap(Bundle.module.url(forResource: "apodini_https_cert_localhost.key", withExtension: "pem")).path
                )
            )
            GRPC(packageName: "de.lukaskollmer", serviceName: "TestWebService")
        }
    }
    
    
    func testReflection() throws {
        struct WebService: Apodini.WebService {
            var content: some Component {
                Text("Hello World")
                    .endpointName("Root")
                Group("team") {
                    Text("Alice and Bob")
                        .endpointName("GetTeam")
                }
                Group("api") {
                    Text("").endpointName("GetPosts")
                    Text("").endpointName("AddPost")
                    Text("").endpointName("DeletePost")
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
            let terminationInfo = try grpcurl.launchSync()
            return (terminationInfo.exitCode, try grpcurl.readStdoutToEnd())
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
              rpc GetTeam ( .google.protobuf.Empty ) returns ( .de.lukaskollmer.Text___Response );
              rpc Root ( .google.protobuf.Empty ) returns ( .de.lukaskollmer.Text___Response );
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
              rpc AddPost ( .google.protobuf.Empty ) returns ( .de.lukaskollmer.Text___Response );
              rpc DeletePost ( .google.protobuf.Empty ) returns ( .de.lukaskollmer.Text___Response );
              rpc GetPosts ( .google.protobuf.Empty ) returns ( .de.lukaskollmer.Text___Response );
            }
            """
        ]
        XCTAssert(responseParts.allSatisfy { describeServices.output.contains($0) })
        XCTAssertEqual(describeServices.output.components(separatedBy: " is a service:").count - 1, responseParts.count)
    }
}


struct EchoHandler<Input: Codable & ResponseTransformable>: Handler {
    @Parameter var value: Input
    func handle() async throws -> some ResponseTransformable {
        value
    }
}


extension GRPCInterfaceExporterTests {
    func testUnaryEndpoint() throws {
        struct WebService: Apodini.WebService {
            var content: some Component {
                Text("Hello World")
                    .endpointName("Root")
                Group("team") {
                    Text("Alice and Bob")
                        .endpointName("GetTeam")
                }
                EchoHandler<String>().endpointName("EchoString")
                EchoHandler<Int>().endpointName("EchoInt")
                EchoHandler<[Double]>().endpointName("EchoDoubles")
                Group("api") {
                    Text("A").endpointName("GetPost")
                    Text("B").endpointName("AddPost")
                    Text("C").endpointName("DeletePost")
                    BlockBasedHandler<[String]> { ["", "a", "b", "c", "d"] }.endpointName("ListPosts")
                    BlockBasedHandler<[Int]> { [0, 1, 2, 3, 4, -52] }.endpointName("ListIDs")
                    BlockBasedHandler<Int> { 1 }.endpointName("GetAnInt")
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
            try makeTestRequestUnary(
                method: "de.lukaskollmer.TestWebService.EchoString",
                WrappedProtoValue<String>(value: "Hello there."),
                outputType: WrappedProtoValue<String>.self
            ).value,
            "Hello there."
        )
        
        do {
            // For the same reason as outlined below, we get back a String and have to compare against that...
            let responseJsonString = try makeTestRequestUnary(method: "de.lukaskollmer.TestWebService.EchoInt", WrappedProtoValue<Int>(value: 123454321))
            let responseJsonObj = try JSONSerialization.jsonObject(with: try XCTUnwrap(responseJsonString.data(using: .utf8)))
            let responseJsonDict = try XCTUnwrap(responseJsonObj as? [String: String])
            XCTAssertEqual(responseJsonDict, ["value": "123454321"])
        }
        
        XCTAssertEqual(
            try makeTestRequestUnary(
                method: "de.lukaskollmer.TestWebService.EchoDoubles",
                WrappedProtoValue<[Double]>(value: [0, 1, 2, 3, .zero, -.zero, .pi]),
                outputType: WrappedProtoValue<[Double]>.self
            ).value,
            [0, 1, 2, 3, .zero, -.zero, .pi]
        )
        
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
            let dict = try XCTUnwrap(object as? [String: [String]])
            XCTAssertEqual(dict, ["value": ["0", "1", "2", "3", "4", "-52"]])
        }
    }
}


// MARK: Service-Side Streaming

class FakeTimer: Apodini.ObservableObject {
    @Apodini.Published private var _trigger = true
    func secondPassed() {
        _trigger.toggle()
    }
}

struct Rocket: Handler {
    @Parameter(.mutability(.constant)) var start: Int = 10
    @State var counter = -1
    @ObservedObject var timer = FakeTimer()
    
    func handle() -> Apodini.Response<String> {
        timer.secondPassed()
        counter += 1
        if counter == start {
            return .final("🚀🚀🚀 Launch !!! 🚀🚀🚀")
        } else {
            return .send("\(start - counter)...")
        }
    }
    
    var metadata: AnyHandlerMetadata {
        Pattern(.serviceSideStream)
    }
}


extension GRPCInterfaceExporterTests {
    func testServiceSideStreamingEndpoint() throws {
        struct WebService: Apodini.WebService {
            var content: some Component {
                Rocket().endpointName("RocketCountdown")
            }
        }
        
        TestGRPCExporterCollection().configuration.configure(app)
        let visitor = SyntaxTreeVisitor(modelBuilder: SemanticModelBuilder(app))
        WebService().accept(visitor)
        visitor.finishParsing()
        try app.start()
        
        struct RocketInput: Codable {
            let start: Int
        }
        let rawResponses = try makeTestRequestServiceSideStream(method: "de.lukaskollmer.TestWebService.RocketCountdown", RocketInput(start: 10))
        let responses = try rawResponses.map { try JSONDecoder().decode(WrappedProtoValue<String>.self, from: try XCTUnwrap($0.data(using: .utf8))) }
        XCTAssertEqual(responses, [
            .init(value: "10..."),
            .init(value: "9..."),
            .init(value: "8..."),
            .init(value: "7..."),
            .init(value: "6..."),
            .init(value: "5..."),
            .init(value: "4..."),
            .init(value: "3..."),
            .init(value: "2..."),
            .init(value: "1..."),
            .init(value: "🚀🚀🚀 Launch !!! 🚀🚀🚀")
        ])
    }
}


struct ClientSideStreamingGreeter: Apodini.Handler {
    @Environment(\.connection) var connection
    @Parameter var name: String
    @State private var names: [String] = []
    
    func handle() -> Response<String> {
        switch connection.state {
        case .open:
            names.append(name)
            return .send()
        case .end:
            names.append(name)
            fallthrough
        case .close:
            switch names.count {
            case 0:
                return .final("Hello!")
            case 1:
                return .final("Hello, \(names[0])")
            default:
                return .final("Hello, \(names[0..<(names.endIndex - 1)].joined(separator: ", ")), and \(names.last!)")
            }
        }
    }
}


extension GRPCInterfaceExporterTests {
    func testClientSideStreamingEndpoint() throws {
        struct WebService: Apodini.WebService {
            var content: some Component {
                ClientSideStreamingGreeter()
                    .pattern(.clientSideStream)
                    .endpointName("Greet")
            }
        }
        
        TestGRPCExporterCollection().configuration.configure(app)
        let visitor = SyntaxTreeVisitor(modelBuilder: SemanticModelBuilder(app))
        WebService().accept(visitor)
        visitor.finishParsing()
        try app.start()
        
        let grpcurlBin = try XCTUnwrap(Self.grpcurlExecutableUrl())
        
        let grpcurl = ChildProcess(
            executableUrl: grpcurlBin,
            arguments: [
                "-insecure", "-d", "@", "localhost:50051", "de.lukaskollmer.TestWebService.Greet"
            ],
            workingDirectory: nil,
            captureOutput: true,
            redirectStderrToStdout: true,
            launchInCurrentProcessGroup: false,
            environment: [:],
            inheritsParentEnvironment: true
        )
        let grpcurlExitExpectation = XCTestExpectation(description: "grpcurl exit")
        try grpcurl.launchAsync { terminationInfo in
            XCTAssertEqual(terminationInfo.exitCode, 0)
            grpcurlExitExpectation.fulfill()
        }
        let inputFH = grpcurl.stdinPipe.fileHandleForWriting
        try inputFH.write(contentsOf: "{ \"name\": \"Lukas\" }\n".data(using: .utf8)!)
        try inputFH.write(contentsOf: "{ \"name\": \"Paul\" }\n".data(using: .utf8)!)
        try inputFH.write(contentsOf: "{ \"name\": \"Bernd\" }\n".data(using: .utf8)!)
        try inputFH.close()
        wait(for: [grpcurlExitExpectation], timeout: 10)
        let output = try grpcurl.readStdoutToEnd()
        struct Response: Codable {
            let value: String
        }
        XCTAssertEqual(try JSONDecoder().decode(Response.self, from: output.data(using: .utf8)!).value, "Hello, Lukas, Paul, and Bernd")
    }
    
    
    // The test case is called testResponseHeaders, but it does in fact do a lot more than that,
    // because it also serves as a proof-of-concept of using `EmbeddedChannel`s for testing the gRPC IE,
    // rather than relying on grpcurl.
    func testResponseHeaders() throws {
        struct WebService: Apodini.WebService {
            var content: some Component {
                Text("Hello World")
                    .endpointName("Root")
                Group("team") {
                    Text("Alice and Bob")
                        .endpointName("GetTeam")
                }
                Group("api") {
                    Text("A").endpointName("GetPost")
                    Text("B").endpointName("AddPost")
                    Text("C").endpointName("DeletePost")
                    BlockBasedHandler<[String]> { ["", "a", "b", "c", "d"] }.endpointName("ListPosts")
                    BlockBasedHandler<[Int]> { [0, 1, 2, 3, 4, -52] }.endpointName("ListIDs")
                    BlockBasedHandler<[Int: String]> { [0: "0", 1: "1", 2: "2"] }.endpointName("ListIDs2")
                    BlockBasedHandler<Int> { 1 }.endpointName("GetAnInt")
                }.gRPCServiceName("API")
            }
        }
        
        TestGRPCExporterCollection().configuration.configure(app)
        let visitor = SyntaxTreeVisitor(modelBuilder: SemanticModelBuilder(app))
        WebService().accept(visitor)
        visitor.finishParsing()
        // Intentionally not starting the app here...
        
        let grpcIE = try XCTUnwrap(app.firstInterfaceExporter(ofType: GRPCInterfaceExporter.self))
        
        let channelCloseExpectation = XCTestExpectation(description: "NIO outbound channel close")
        let messageOutInterceptor = OutboundInterceptingChannelHandler<GRPCMessageHandler.OutboundOut>()
        let httpOutInterceptor = OutboundInterceptingChannelHandler<HTTP2Frame.FramePayload>(closeExpectation: channelCloseExpectation)
        
        // We create an embedded channel which receives already-decoded input (skipping the HTTP2 frame -> grpc handler input step here),
        // and otherwise behaves the same was as the "normal" gRPC channel pipeline.
        // We also add some intercepting handlers, which allows us to a) check that the data send through the pipeline at certain stages
        // of the message handling process is what we'd expect, and b) detect the end of the connection.
        let channel = EmbeddedChannel(handlers: [
            OutboundSinkholeChannelHandler(),
            httpOutInterceptor,
            GRPCResponseEncoder(),
            messageOutInterceptor,
            GRPCMessageHandler(server: grpcIE.server)
        ])
        // The HTTP/2 headers with which the client initiated the connection
        let clientHeaders = HPACKHeaders {
            $0[.methodPseudoHeader] = .POST
            $0[.schemePseudoHeader] = "https"
            $0[.pathPseudoHeader] = "/de.lukaskollmer.TestWebService/GetTeam"
            $0[.contentType] = .gRPC(.proto)
        }
        try channel.writeInbound(GRPCMessageHandler.Input.openStream(clientHeaders))
        try channel.writeInbound(GRPCMessageHandler.Input.message(GRPCMessageIn(
            remoteAddress: nil,
            requestHeaders: clientHeaders,
            payload: ByteBuffer()
        )))
        try channel.writeInbound(GRPCMessageHandler.Input.closeStream(reason: .client))
        
        wait(for: [channelCloseExpectation], timeout: 5)
        XCTAssert(try channel.finish(acceptAlreadyClosed: true).isClean)
        
        XCTAssertEqual(messageOutInterceptor.interceptedData.count, 2)
        XCTAssertEqual(messageOutInterceptor.interceptedData[0].asSingleMessage, GRPCMessageOut.singleMessage(
            headers: HPACKHeaders {
                $0[.contentType] = .gRPC(.proto)
            },
            payload: ByteBuffer(bytes: [10, 13, 65, 108, 105, 99, 101, 32, 97, 110, 100, 32, 66, 111, 98]),
            closeStream: true
        ))
        XCTAssertEqual(messageOutInterceptor.interceptedData[1], .closeStream(trailers: HPACKHeaders()))
    }
}


extension GRPCMessageHandler.Output {
    func isMessage(_ expectedMessage: GRPCMessageOut) -> Bool {
        switch self {
        case .closeStream, .error:
            return false
        case .message(let messageOut, _):
            return messageOut == expectedMessage
        }
    }
    
    var asSingleMessage: GRPCMessageOut? {
        switch self {
        case .closeStream, .error:
            return nil
        case .message(let message, _):
            return message
        }
    }
    
    var asCloseStream: HPACKHeaders? {
        switch self {
        case .closeStream(let trailers):
            return trailers
        case .error, .message:
            return nil
        }
    }
}


// MARK: gRPC test request stuff

extension GRPCInterfaceExporterTests {
    /// Sends a single request to the specified unary method.
    /// - returns: the response object, decoded from the response JSON string as the specified type
    private func makeTestRequestUnary<In: Encodable, Out: Decodable>(
        serverAddress: String = "localhost",
        port: Int = 50051,
        method: String,
        _ input: In,
        outputType: Out.Type
    ) throws -> Out {
        let response: String = try makeTestRequestUnary(serverAddress: serverAddress, port: port, method: method, input)
        // grpcurl only supports JSON output, which means we sadly can't decode the actual proto bytes here :/
        return try JSONDecoder().decode(Out.self, from: ByteBuffer(string: response))
    }
    
    
    /// Sends a single request to the specified unary method.
    /// - returns: a JSON string representing the response to the request
    private func makeTestRequestUnary<In: Encodable>(
        serverAddress: String = "localhost",
        port: Int = 50051,
        method: String,
        _ input: In
    ) throws -> String {
        guard let grpcurlBin = Self.grpcurlExecutableUrl() else {
            throw XCTSkip("Unable to find grpcurl")
        }
        let inputJson = try XCTUnwrap(String(data: try JSONEncoder().encode(input), encoding: .utf8))
        let grpcurl = ChildProcess(
            executableUrl: grpcurlBin,
            arguments: ["-insecure", "-emit-defaults", "-d", inputJson, "localhost:50051", method],
            workingDirectory: nil,
            captureOutput: true,
            redirectStderrToStdout: true,
            launchInCurrentProcessGroup: false,
            environment: [:],
            inheritsParentEnvironment: true
        )
        let terminationInfo = try grpcurl.launchSync()
        let output = try grpcurl.readStdoutToEnd()
        XCTAssertEqual(
            terminationInfo.exitCode,
            0,
            "grpcurl unexpectedly exited w/ non-zero exit code \(terminationInfo.exitCode). (output: \(output))"
        )
        return output
    }
    
    
    private func makeTestRequestServiceSideStream<In: Encodable>(
        serverAddress: String = "localhost",
        port: Int = 50051,
        method: String,
        _ input: In
    ) throws -> [String] {
        // In this regard, service-side-streaming requests are in fact identical to
        // unary requests (some data in, get a string back containing the response(s)).
        let rawResponse = try makeTestRequestUnary(serverAddress: serverAddress, port: port, method: method, input)
        var responses: [String] = []
        var currentResponse: [String] = []
        for line in rawResponse.split(separator: "\n") {
            if line == "{" { // no indent and opening braces -> starting a new object
                if !currentResponse.isEmpty {
                    responses.append(currentResponse.joined(separator: "\n"))
                    currentResponse = []
                }
            }
            currentResponse.append(String(line))
        }
        if !currentResponse.isEmpty {
            responses.append(currentResponse.joined(separator: "\n"))
        }
        return responses
    }
}
