//
//  File.swift
//  File
//
//  Created by Paul Schmiedmayer on 7/19/21.
//

#if DEBUG || RELEASE_TESTING
@testable import Apodini
import ApodiniHTTP
import NIO
@_exported import XCTApodini
@_implementationOnly import XCTVapor


public typealias HTTPHeaders = [(key: String, value: String)]

extension HTTPHeaders {
    func compare(with headers: Self) -> Bool {
        guard self.count == headers.count else {
            return false
        }
        
        let keys = self.map({ $0.key.lowercased() })
        for key in keys {
            let values = self.filter({ $0.key == key }).map({ $0.value }).sorted()
            let headerValues = headers.filter({ $0.key == key }).map({ $0.value }).sorted()
            if values != headerValues {
                return false
            }
        }
        
        return true
    }
}

public struct HTTPRequest {
    public struct Method: Equatable {
        public static var GET = Method("GET")
        public static var POST = Method("POST")
        public static var PUT = Method("PUT")
        public static var DELETE = Method("DELETE")
        
        
        let method: String
        
        
        public init(_ method: String) {
            self.method = method
        }
    }
    
    
    public let path: String
    public let method: Method
    public let headers: HTTPHeaders
    public let body: ByteBuffer
    
    
    public init(path: String = "/v1", method: Method = .GET, headers: HTTPHeaders = [], body: ByteBuffer = ByteBuffer()) {
        self.path = path
        self.method = method
        self.headers = headers
        self.body = body
    }
}

extension HTTPRequest: Equatable {
    public static func == (lhs: HTTPRequest, rhs: HTTPRequest) -> Bool {
        guard  lhs.path == rhs.path, lhs.method == rhs.method, lhs.body == rhs.body else {
            return false
        }
        
        return lhs.headers.compare(with: rhs.headers)
    }
}

extension Vapor.HTTPMethod {
    init(_ method: XCTApodiniHTTP.HTTPRequest.Method) {
        self.init(rawValue: method.method)
    }
}

extension Vapor.HTTPHeaders {
    init(_ headers: [String: String]) {
        self.init(headers.uniqued(with: \.key))
    }
}


public struct HTTPResponse {
    public struct Status: Equatable {
        public static var ok = Status(200)
        public static var created = Status(201)
        public static var noContent = Status(204)
        public static var seeOther = Status(303)
        public static var badRequest = Status(400)
        public static var unauthorized = Status(401)
        public static var forbidden = Status(403)
        public static var notFound = Status(403)
        public static var interenalServerError = Status(500)
        public static var notImplemented = Status(501)
        
        
        let code: UInt
        
        
        public init(_ code: UInt) {
            precondition(code >= 100 && code <= 599)
            self.code = code
        }
    }
    
    
    public let status: Status
    public let headers: HTTPHeaders
    public let body: ByteBuffer
    
    
    public init(status: Status = .ok, headers: HTTPHeaders = [], body: ByteBuffer = ByteBuffer()) {
        self.status = status
        self.headers = headers
        self.body = body
    }
    
    
    public func decodeBody<D: Decodable>(decoder: JSONDecoder = JSONDecoder(), _ type: D.Type = D.self) throws -> D {
        try XCTUnwrap(
            try body.getJSONDecodable(type.self, decoder: decoder, at: body.readerIndex, length: body.readableBytes)
        )
    }
}

extension HTTPResponse: Equatable {
    public static func == (lhs: HTTPResponse, rhs: HTTPResponse) -> Bool {
        guard  lhs.status == rhs.status, lhs.body == rhs.body else {
            return false
        }
        
        return lhs.headers.compare(with: rhs.headers)
    }
}

extension XCTHTTPResponse {
    var response: HTTPResponse {
        HTTPResponse(status: HTTPResponse.Status(status.code), headers: headers.map({ $0 }), body: body)
    }
}

public struct HTTPCheck {
    public struct Expectation {
        public static var none = Expectation({ _ in })
        public static func closure(_ closure: @escaping (HTTPResponse) throws -> ()) -> Expectation {
            Expectation(closure)
        }
        public static func response(_ expectedResponse: HTTPResponse) -> Expectation {
            Expectation { response in
                XCTAssertEqual(response, expectedResponse)
            }
        }
        
        
        var executeExpectation: (HTTPResponse) throws -> ()
        
        
        init(_ executeExpectation: @escaping (HTTPResponse) throws -> ()) {
            self.executeExpectation = executeExpectation
        }
    }
    
    
    let request: HTTPRequest
    let expectation: Expectation
    
    
    public init(_ request: HTTPRequest = HTTPRequest(), expectation: Expectation = .none) {
        self.request = request
        self.expectation = expectation
    }
    
    public init(_ request: HTTPRequest = HTTPRequest(), expectation response: HTTPResponse) {
        self.request = request
        self.expectation = .response(response)
    }
    
    public init(_ request: HTTPRequest = HTTPRequest(), expectation closure: @escaping (HTTPResponse) throws -> ()) {
        self.request = request
        self.expectation = .closure(closure)
    }
}

@resultBuilder
public enum HTTPCheckBuilder {
    public static func buildBlock(_ httpCheck: HTTPCheck...) -> [HTTPCheck] {
        httpCheck
    }
}



open class XCTApodiniHTTPTest: XCTApodiniTest {
    private struct TestWebService<C: Component>: WebService {
        let content: C
        let configuration: Configuration
        
        
        init(_ content: C, configuration: Configuration = MockExporter()) {
            self.content = content
            self.configuration = configuration
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
    
    
    @discardableResult
    public func XCTHTTPCheck<C: Component>(
        _ component: C,
        configuration: Configuration = HTTP(),
        @HTTPCheckBuilder _ checks: () throws -> ([HTTPCheck]) = { [] },
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> HTTPResponse? {
        return try XCTHTTPCheck(
            webService: TestWebService(component, configuration: configuration),
            checks,
            message(),
            file: file,
            line: line
        )
    }
    
    
    @discardableResult
    public func XCTHTTPCheck<W: WebService>(
        webService: W,
        @HTTPCheckBuilder _ checks: () throws -> ([HTTPCheck]) = { [] },
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> HTTPResponse? {
        let app = try W.start(waitForCompletion: false, webService: webService)
        
        var lastResponse: HTTPResponse?
        for check in try checks() {
            let request = check.request
            try app.vapor.app.testable(method: .inMemory)
                .test(
                    HTTPMethod(request.method),
                    request.path,
                    headers: Vapor.HTTPHeaders(request.headers),
                    body: request.body
                ) { vaporResponse in
                    let reponse = try XCTUnwrap(vaporResponse.response)
                    try check.expectation.executeExpectation(reponse)
                    lastResponse = reponse
                }
        }
        return lastResponse
    }
}
#endif
