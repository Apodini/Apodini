//
//  Guard.swift
//  
//
//  Created by Paul Schmiedmayer on 6/27/20.
//

import NIO
import Vapor


public protocol Guard {
    func check() -> EventLoopFuture<Void>
}
