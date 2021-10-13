//
//  Expectation.swift
//  
//
//  Created by Paul Schmiedmayer on 5/12/21.
//

#if DEBUG || RELEASE_TESTING
@testable import Apodini


public enum Expectation<R: Encodable & Equatable> {
    public static var empty: Expectation<Empty> {
        Expectation<Empty>.response(nil)
    }
    
    public static func status(_ status: Status) -> Expectation<Empty> {
        Expectation<Empty>.response(status: status, nil)
    }
    
    public static func status(_ status: Status) -> Expectation<R> {
        Expectation<R>.response(status: status, nil)
    }
    
    public static func connectionEffect(_ connectionEffect: ConnectionEffect) -> Expectation<Empty> {
        Expectation<Empty>.response(connectionEffect: connectionEffect, nil)
    }
    
    public static func connectionEffect(_ connectionEffect: ConnectionEffect) -> Expectation<R> {
        Expectation<R>.response(connectionEffect: connectionEffect, nil)
    }
    
    case response(status: Status? = nil, connectionEffect: ConnectionEffect = .close, R?)
    case error
    
    
    func check(_ responseFuture: EventLoopFuture<Response<R>>) throws -> R? {
        switch self {
        case let .response(status, connectionEffect, expectedResponse):
            let untypedResponse = try responseFuture.wait()
            let response = try XCTUnwrap(untypedResponse.typed(R.self))
            
            XCTAssertEqual(response.content, expectedResponse)
            XCTAssertEqual(response.connectionEffect, connectionEffect)
            XCTAssertEqual(response.status, status)
            
            return response.content
        case .error:
            do {
                let response = try responseFuture.wait()
                XCTFail("Expected an error that was not encountered. Got: \(response)")
            } catch {
                return nil
            }
            return nil
        }
    }
}
#endif
