//
//  RequestInjectableTests.swift
//  
//
//  Created by Lorena Schlesinger on 21.11.20.
//

import XCTest
import Vapor
@testable import Apodini

final class RequestInjectableTests: XCTestCase {
    
    func testBodyInjectable() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        
        struct Message: Content {
            var key: String
        }
               
        struct SomeComponent: Component {
            
            @Body
            var body: Message
            
            func handle() -> Message {
                body
            }
        }
        
        let message: Message = Message(key: "test")
        let messageJson = try JSONEncoder().encode(message)
        let messageString = String(data: messageJson, encoding: .utf8)!
        
        var body = ByteBufferAllocator().buffer(capacity: 0)
        body.writeString(messageString)
        
        app.routes.post("some") {req in
            req.enterRequestContext(with: SomeComponent()) { component in
                return component.handle().encodeResponse(for: req)
            }
        }
        
        try app.testable().test(.POST, "/some", body: body) { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, messageString)
        }
    }
    
}
