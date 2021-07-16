//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import XCTApodini
import ApodiniVaporSupport
import Vapor
@testable import Apodini
import XCTVapor

typealias Response = Apodini.Response

class ResultTransformerTests: XCTApodiniTest {
    struct MockHandler: Handler {
        func handle() -> String { "" }
    }
    
    let transformer = VaporResponseTransformer<MockHandler>(JSONEncoder())
    
    let blobTransformer = VaporBlobResponseTransformer()
    
    func testNothing() throws {
        let eventLoop = app.eventLoopGroup.next()
        
        let response = try eventLoop
                            .makeSucceededFuture(Response<String>.nothing)
                            .transform(using: transformer)
                            .wait()
        
        XCTAssertEqual(response.status, .noContent)
        XCTAssertEqual(response.body.count, 0)
    }
    
    func testNothingBlob() throws {
        let eventLoop = app.eventLoopGroup.next()
        
        let response = try eventLoop
                            .makeSucceededFuture(Response<Blob>.nothing)
                            .transform(using: blobTransformer)
                            .wait()
        
        XCTAssertEqual(response.status, .noContent)
        XCTAssertEqual(response.body.count, 0)
    }
    
    func testCustomStatus() throws {
        let eventLoop = app.eventLoopGroup.next()
        
        let response = try eventLoop
                            .makeSucceededFuture(Response<String>.final("", status: .redirect))
                            .transform(using: transformer)
                            .wait()
        
        XCTAssertEqual(response.status, .seeOther)
        XCTAssertEqual(response.body.string, "\"\"")
    }
    
    func testApodiniError() throws {
        let eventLoop = app.eventLoopGroup.next()
        
        do {
            _ = try eventLoop
                .makeFailedFuture(ApodiniError(
                    type: .badInput,
                    reason: "Nothing Wrong",
                    description: "This test case just needs an error with description🤷‍♂️"))
                                .transform(using: transformer)
                                .wait()
            XCTFail("Should have thrown!")
        } catch {
            let abort = try XCTUnwrap(error as? AbortError)
            
            XCTAssertEqual(abort.status, .badRequest)
            XCTAssertEqual(abort.headers, HTTPHeaders())
            
            #if DEBUG
            XCTAssertEqual(abort.reason, "Bad Input: Nothing Wrong (This test case just needs an error with description🤷‍♂️)")
            #else
            XCTAssertEqual(abort.reason, "Bad Input: Nothing Wrong")
            #endif
        }
    }
    
    func testApodiniErrorBlob() throws {
        let eventLoop = app.eventLoopGroup.next()
        
        do {
            _ = try eventLoop
                .makeFailedFuture(ApodiniError(type: .serverError))
                                .transform(using: blobTransformer)
                                .wait()
            XCTFail("Should have thrown!")
        } catch {
            let abort = try XCTUnwrap(error as? AbortError)
            
            XCTAssertEqual(abort.status, .internalServerError)
        }
    }
    
    func testApodiniErrorCustomOptions() throws {
        let eventLoop = app.eventLoopGroup.next()
        
        do {
            _ = try eventLoop
                .makeFailedFuture(ApodiniError(
                    type: .badInput,
                    reason: "Nothing Wrong",
                    description: "This test case just needs an error with description🤷‍♂️",
                    .init([
                        .httpRespnoseStatus(.httpVersionNotSupported),
                        .httpHeaders(.init(.init(arrayLiteral: ("headerName", "headerValue"))))
                    ])))
                                .transform(using: transformer)
                                .wait()
            XCTFail("Should have thrown!")
        } catch {
            let abort = try XCTUnwrap(error as? AbortError)
            
            XCTAssertEqual(abort.status, .httpVersionNotSupported)
            XCTAssertEqual(abort.headers.first(name: "headerName"), "headerValue")
        }
    }
}
