//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
import Apodini
import ApodiniObserve
import Logging
import Tracing
import ApodiniAudit


struct TraditionalGreeter: Handler {
    // one cannot change their surname, but it can be ommitted
    @Parameter(.mutability(.constant)) var surname: String = ""
    // one can change their age, happy birthday!! 🎉
    @Parameter(.mutability(.constant)) var age: Int
    // one can switch between formal and informal greeting at any time
    @Parameter var name: String?
    
    @Environment(\.connection) var connection: Connection
    @Environment(\.logger) var logger: Logger
    @Environment(\.tracer) var tracer: Tracer

    
    func handle() -> Response<String> {
        let span = tracer.startSpan("TraditionalGreeter.handle()", baggage: .topLevel)
        defer { span.end() }
        logger.info("\(connection.state)")
        
        switch connection.state {
        case .end, .close:
            return.end
        default:
            break
        }

        if let firstName = name {
            return .send("Hi, \(firstName)! You are now \(age) years old!")
        } else {
            return .send("Hello, \(surname)! You are now \(age) years old!")
        }
    }
    
    var metadata: AnyHandlerMetadata {
        SelectBestPractices(.enable, NoCRUDVerbsInURLPathSegments.self)
    }
}
