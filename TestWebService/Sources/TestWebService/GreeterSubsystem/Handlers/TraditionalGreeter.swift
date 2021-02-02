//
//  TraditionalGreeter.swift
//  
//
//  Created by Paul Schmiedmayer on 1/19/21.
//

import Apodini
import Logging

struct TraditionalGreeter: Handler {
    // one cannot change their surname, but it can be ommitted
    @Parameter(.mutability(.constant)) var surname: String = ""
    // one can change their age, happy birthday!! 🎉
    @Parameter(.mutability(.constant)) var age: Int
    // one can switch between formal and informal greeting at any time
    @Parameter var name: String?

    @Environment(\.connection) var connection: Connection
    @Environment(\.logger) var logger: Logger

    func handle() -> Response<String> {
        logger.info("\(connection.state)")

        if connection.state == .end {
            return .end
        }

        if let firstName = name {
            return .send("Hi, \(firstName)! You are now \(age) years old!")
        } else {
            return .send("Hello, \(surname)! You are now \(age) years old!")
        }
    }
}
