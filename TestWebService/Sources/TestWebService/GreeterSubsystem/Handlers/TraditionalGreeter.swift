//
//  TraditionalGreeter.swift
//  
//
//  Created by Paul Schmiedmayer on 1/19/21.
//

import Apodini
import Logging


struct TraditionalGreeter: Handler {

    @Parameter var surname: String = ""

    @Parameter var age: Int32
    
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
