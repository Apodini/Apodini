import Apodini
@_exported import ApodiniNetworking
import XCTest
import AsyncHTTPClient



public struct XCTLKHTTPRequest {
    public let version: HTTPVersion
    public let method: HTTPMethod
    public let url: LKURL
    public let headers: HTTPHeaders
    public let body: ByteBuffer // TODO support streams here!
    
    fileprivate let file: StaticString
    fileprivate let line: UInt
    
    public init(
        version: HTTPVersion,
        method: HTTPMethod,
        url: LKURL,
        headers: HTTPHeaders = [:],
        body: ByteBuffer = .init(),
        file: StaticString = #file,
        line: UInt = #line
    ) {
        self.version = version
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
        self.file = file
        self.line = line
    }
}

//struct XCTLKHTTPResponse {}


/// How a tester --- absent of any further information --- should treat the expected body of a response.
public enum XCTApodiniNetworkingRequestResponseTesterResponseBodyExpectedBodyStorageType {
    case buffer
    case stream
}


public protocol XCTApodiniNetworkingRequestResponseTester {
    func performTest(
        _ request: XCTLKHTTPRequest,
        expectedBodyType: XCTApodiniNetworkingRequestResponseTesterResponseBodyExpectedBodyStorageType,
        responseStart: @escaping (LKHTTPResponse) throws -> Void,
        responseEnd: (LKHTTPResponse) throws -> Void
    ) throws
    
//    func performServiceSideStreamingEndpointTest(
//        _ request: XCTLKHTTPRequest,
//        streamEventObserver: LKDataStream.ObserverFn?,
//        fullResponseValidator: (LKHTTPResponse) throws -> Void
//    ) throws
}



private func makeUrl(version: HTTPVersion, path: String) -> LKURL {
    return LKURL(string: "\(version.major > 1 ? "https" : "http")://127.0.0.1:8000/\(path.hasPrefix("/") ? path.dropFirst() : path[...])")!
}

extension XCTApodiniNetworkingRequestResponseTester {
    public func test(
        version: HTTPVersion = .http1_1,
        _ method: HTTPMethod,
        _ path: String,
        headers: HTTPHeaders = [:],
        body: ByteBuffer = .init(),
        expectedBodyType: XCTApodiniNetworkingRequestResponseTesterResponseBodyExpectedBodyStorageType = .buffer,
        file: StaticString = #file,
        line: UInt = #line,
        responseStart: @escaping (LKHTTPResponse) throws -> () = { _ in },
        responseEnd: (LKHTTPResponse) throws -> ()
    ) throws {
        //self.performTest(LKHTTPRequest(method: <#T##HTTPMethod#>, url: <#T##LKURL#>, eventLoop: ))
        do {
            try self.performTest(XCTLKHTTPRequest(
                version: version,
                method: method,
                //url: LKURL(stringLiteral: "\(version.major > 1 ? "https" : "http")://127.0.0.1:8000/\(path.hasPrefix("/") ? path.dropFirst() : path[...])"),
                url: makeUrl(version: version, path: path),
                headers: headers,
                body: body,
                file: file,
                line: line
            ), expectedBodyType: expectedBodyType, responseStart: responseStart, responseEnd: responseEnd)
            //try validateResponse(response)
        } catch {
            XCTFail("\(error)", file: file, line: line)
            throw error
        }
    }
    
//    public func testServiceSideStreaming(
//        version: HTTPVersion = .http1_1,
//        _ method: HTTPMethod,
//        _ path: String,
//        headers: HTTPHeaders = [:],
//        body: ByteBuffer = .init(),
//        file: StaticString = #file,
//        line: UInt = #line,
//        streamEventObserver: LKDataStream.ObserverFn?,
//        validateResponse: (LKHTTPResponse) throws -> Void
//    ) throws {
//        do {
//            try self.performServiceSideStreamingEndpointTest(
//                XCTLKHTTPRequest(version: version, method: method, url: makeUrl(version: version, path: path), headers: headers, body: body),
//                streamEventObserver: streamEventObserver,
//                fullResponseValidator: validateResponse
//            )
//        } catch {
//            XCTFail("\(error)", file: file, line: line)
//            throw error
//        }
//    }
}




extension Apodini.Application {
    public enum TestingMethod: Hashable {
        case inMemory
        //case actualRequests // this would be hell to implement
        case actualRequests(hostname: String?, port: Int?)
        
        public static var actualRequests: TestingMethod {
            .actualRequests(hostname: nil, port: nil)
        }
    }
    
    
    public func testable(_ methods: Set<TestingMethod> = [.inMemory]) -> XCTApodiniNetworkingRequestResponseTester {
        return MultiplexingTester(testers: methods.map { method in
            switch method {
            case .inMemory:
                return InMemoryTester(app: self)
            case .actualRequests(let hostname, let port):
                return ActualRequestsTester(app: self, hostname: hostname, port: port)
            }
        })
    }
    
    
    private struct MultiplexingTester: XCTApodiniNetworkingRequestResponseTester {
        let testers: [XCTApodiniNetworkingRequestResponseTester]
        
        func performTest(
            _ request: XCTLKHTTPRequest,
            expectedBodyType: XCTApodiniNetworkingRequestResponseTesterResponseBodyExpectedBodyStorageType,
            responseStart: @escaping (LKHTTPResponse) throws -> Void,
            responseEnd: (LKHTTPResponse) throws -> Void
        ) throws {
            for tester in testers {
                try tester.performTest(request, expectedBodyType: expectedBodyType, responseStart: responseStart, responseEnd: responseEnd)
            }
        }
    }
    
    
    private struct InMemoryTester: XCTApodiniNetworkingRequestResponseTester {
        let app: Apodini.Application
        
        func performTest(
            _ request: XCTLKHTTPRequest,
            expectedBodyType: XCTApodiniNetworkingRequestResponseTesterResponseBodyExpectedBodyStorageType,
            responseStart: @escaping (LKHTTPResponse) throws -> Void,
            responseEnd: (LKHTTPResponse) throws -> Void
        ) throws {
            let httpRequest = LKHTTPRequest(
                method: request.method,
                url: request.url,
                headers: request.headers,
                bodyStorage: .buffer(request.body), // TODO add support for client-side-stream-based tests?
                eventLoop: app.eventLoopGroup.next()
            )
            let response = try app.lkHttpServer.respond(to: httpRequest).makeHTTPResponse(for: httpRequest).wait()
            try responseEnd(response)
        }
    }
    
    
    private struct ActualRequestsTester: XCTApodiniNetworkingRequestResponseTester {
        let app: Apodini.Application
        let hostname: String?
        let port: Int?
        
        init(app: Apodini.Application, hostname: String?, port: Int?) {
            self.app = app
            self.hostname = hostname
            self.port = port
        }
        
        func performTest(
            _ request: XCTLKHTTPRequest,
            expectedBodyType: XCTApodiniNetworkingRequestResponseTesterResponseBodyExpectedBodyStorageType,
            responseStart: @escaping (LKHTTPResponse) throws -> Void,
            responseEnd: (LKHTTPResponse) throws -> Void
        ) throws {
            precondition(!app.lkHttpServer.isRunning)
            let address: (hostname: String, port: Int)
            switch app.http.address {
            case .hostname(let currentAppHostname, port: let currentAppPort):
                address = (hostname ?? currentAppHostname, port ?? currentAppPort)
                app.http.address = .hostname(address.hostname, port: address.port)
            case .unixDomainSocket(_):
                fatalError("Expected a hostname-based http config")
            }
//            try app.lkHttpServer.start()
//            defer { try! app.lkHttpServer.shutdown() }
//            let httpClient = AsyncHTTPClient.HTTPClient(eventLoopGroupProvider: .shared(app.eventLoopGroup))
//            defer { try! httpClient.syncShutdown() }
//            let response = try httpClient.execute(request: try AsyncHTTPClient.HTTPClient.Request(
//                //url: request.url.pathIncludingQueryAndFragment,
//                url: "http://\(address.hostname):\(address.port)\(request.url.pathIncludingQueryAndFragment)",
//                method: request.method,
//                headers: request.headers,
//                body: .byteBuffer(request.body)
//            ), delegate: ).wait()
//            let httpResponse = LKHTTPResponse(
//                version: response.version,
//                status: response.status,
//                headers: response.headers,
//                //body: response.body ?? .init()
//                bodyStorage: .buffer(response.body ?? .init())
//            )
//            try validator(httpResponse)
            
            try app.lkHttpServer.start()
            defer { try! app.lkHttpServer.shutdown() }
            
            let httpClient = AsyncHTTPClient.HTTPClient(eventLoopGroupProvider: .shared(app.eventLoopGroup))
            defer { try! httpClient.syncShutdown() }
            
//            let httpResponsePromise = app.eventLoopGroup.next().makePromise(of: LKHTTPResponse.self)
            
            let delegate = ActualRequestsTestHTTPClientResponseDelegate(
                expectedBodyType: expectedBodyType,
                responseStart: { response in
                    do {
                        try responseStart(response)
                    } catch {
                        XCTFail("\(error)", file: request.file, line: request.line)
                    }
                }
            )
            
            let responseTask = httpClient.execute(request: try AsyncHTTPClient.HTTPClient.Request(
                url: "\(request.url.scheme)://\(address.hostname):\(address.port)\(request.url.pathIncludingQueryAndFragment)",
                method: request.method,
                headers: request.headers,
                body: .byteBuffer(request.body), // TODO support streams here!
                tlsConfiguration: .clientDefault
            ), delegate: delegate)
            
            //let httpResponse = try httpResponsePromise.futureResult.wait()
            let httpResponse = try responseTask.wait()
            try responseEnd(httpResponse)
            print("returning after validator")
            
//            let response = try httpClient.execute(request: try AsyncHTTPClient.HTTPClient.Request(
//            ), delegate: ).wait()
//            let httpResponse = LKHTTPResponse(
//                version: response.version,
//                status: response.status,
//                headers: response.headers,
//                //body: response.body ?? .init()
//                bodyStorage: .buffer(response.body ?? .init())
//            )
//            try validator(httpResponse)
            
        }
    }
}




private class ActualRequestsTestHTTPClientResponseDelegate: AsyncHTTPClient.HTTPClientResponseDelegate {
    typealias Response = LKHTTPResponse
    
    private let expectedBodyType: XCTApodiniNetworkingRequestResponseTesterResponseBodyExpectedBodyStorageType
    private let response: LKHTTPResponse
    private let responseStart: (LKHTTPResponse) -> Void
    
    fileprivate init(
        expectedBodyType: XCTApodiniNetworkingRequestResponseTesterResponseBodyExpectedBodyStorageType,
        responseStart: @escaping (LKHTTPResponse) -> Void
    ) {
        self.expectedBodyType = expectedBodyType
        self.responseStart = responseStart
        self.response = LKHTTPResponse(
            version: .http1_1,
            status: .imATeapot,
            headers: [:],
            bodyStorage: {
                switch expectedBodyType {
                case .buffer:
                    return .buffer()
                case .stream:
                    return .stream()
                }
            }()
        )
        self.response.bodyStorage.stream?.debugName = "HTTPClientResponse"
    }
    
    func didReceiveHead(task: HTTPClient.Task<Response>, _ head: HTTPResponseHead) -> EventLoopFuture<Void> {
        response.version = head.version
        response.status = head.status
        response.headers = head.headers
        responseStart(response)
        return task.eventLoop.makeSucceededVoidFuture()
    }
    
    
    func didReceiveBodyPart(task: HTTPClient.Task<Response>, _ buffer: ByteBuffer) -> EventLoopFuture<Void> {
        response.bodyStorage.write(buffer)
        return task.eventLoop.makeSucceededVoidFuture()
    }
    
    func didFinishRequest(task: HTTPClient.Task<Response>) throws -> Response {
        response.bodyStorage.stream?.close()
        return response
    }
    
    func didReceiveError(task: HTTPClient.Task<Response>, _ error: Error) {
        print(#function, error)
        task.cancel()
    }
    
    deinit {
        print("-[\(Self.self) \(#function)]")
    }
}
