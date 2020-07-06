//
//  Guard.swift
//  
//
//  Created by Paul Schmiedmayer on 6/27/20.
//

import NIO
import Vapor


public protocol Guard {
    func check(_ request: Request) -> EventLoopFuture<Void>
}


extension Guard {
    func checkInContext(of request: Request) -> EventLoopFuture<Void> {
        request.enterRequestContext(with: self) { component in
            component.check(request)
        }
    }
}
