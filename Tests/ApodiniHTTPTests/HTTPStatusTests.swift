//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import XCTApodini
import ApodiniHTTP
@testable import Apodini
import XCTApodiniNetworking
import Foundation

/// Test that returning ``Status``s and ``ApodiniError``s from Handlers results in the correct HTTP status codes
final class HTTPStatusTests: XCTApodiniTest {
    func testErrorStatuses() throws {
        try StatusWebService().start(app: app)
        
        try assertStatus(route: "/b", status: .badRequest)
        try assertStatus(route: "/c", status: .notFound)
        try assertStatus(route: "/d", status: .unauthorized)
        try assertStatus(route: "/e", status: .forbidden)
        try assertStatus(route: "/f", status: .internalServerError)
        try assertStatus(route: "/g", status: .serviceUnavailable)
        try assertStatus(route: "/h", status: .internalServerError)
    }
    
    func testStatuses() throws {
        try StatusWebService().start(app: app)

        StatusHandler.status = .ok
        try assertStatus(route: "/a", status: .ok)
        StatusHandler.status = .created
        try assertStatus(route: "/a", status: .created)
        StatusHandler.status = .noContent
        try assertStatus(route: "/a", status: .noContent)
        StatusHandler.status = .redirect
        try assertStatus(route: "/a", status: .seeOther)
        StatusHandler.status = .badRequest
        try assertStatus(route: "/a", status: .badRequest)
        StatusHandler.status = .notFound
        try assertStatus(route: "/a", status: .notFound)
        StatusHandler.status = .notModified
        try assertStatus(route: "/a", status: .notModified)
    }
    
    struct StatusHandler: Handler {
        static var status: Status = .ok
        
        func handle() -> Status {
            Self.status
        }
    }
    
    struct BadInputHandler: Handler {
        @Throws(.badInput) var error
        
        func handle() throws -> String { throw error }
    }
    
    struct NotFoundHandler: Handler {
        @Throws(.notFound) var error
        
        func handle() throws -> String { throw error }
    }
    
    struct UnauthenticatedHandler: Handler {
        @Throws(.unauthenticated) var error
        
        func handle() throws -> String { throw error }
    }
    
    struct ForbiddenHandler: Handler {
        @Throws(.forbidden) var error
        
        func handle() throws -> String { throw error }
    }
    
    struct ServerErrorHandler: Handler {
        @Throws(.serverError) var error
        
        func handle() throws -> String { throw error }
    }
    
    struct NotAvailableHandler: Handler {
        @Throws(.notAvailable) var error
        
        func handle() throws -> String { throw error }
    }
    
    struct OtherHandler: Handler {
        @Throws(.other) var error
        
        func handle() throws -> String { throw error }
    }
    
    struct StatusWebService: WebService {
        var content: some Component {
            Group("a") {
                StatusHandler()
            }
            Group("b") {
                BadInputHandler()
            }
            Group("c") {
                NotFoundHandler()
            }
            Group("d") {
                UnauthenticatedHandler()
            }
            Group("e") {
                ForbiddenHandler()
            }
            Group("f") {
                ServerErrorHandler()
            }
            Group("g") {
                NotAvailableHandler()
            }
            Group("h") {
                OtherHandler()
            }
        }
        
        var configuration: Configuration {
            HTTP()
        }
    }
    
    func assertStatus(
        route: String,
        status: HTTPResponseStatus
    ) throws {
        try app.testable().test(.GET, route) { response in
            XCTAssertEqual(response.status, status)
        }
    }
}
