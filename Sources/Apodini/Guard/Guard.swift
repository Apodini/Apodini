//
//  Guard.swift
//  
//
//  Created by Paul Schmiedmayer on 6/27/20.
//

import NIO
import Vapor


public protocol Guard {
    #warning("Consider removing the request parameter once we have a @Request Property Wrapper")
    func check(_ request: Request) -> EventLoopFuture<Void>
}
