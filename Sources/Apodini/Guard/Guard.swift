//
//  Guard.swift
//  
//
//  Created by Paul Schmiedmayer on 6/27/20.
//

import NIO
import Vapor


public protocol SyncGuard {
    func check()
}

public protocol Guard {
    associatedtype GuardResult = Void
    
    func check() -> EventLoopFuture<GuardResult>
}


extension SyncGuard {
    func executeGuardCheck(on request: Vapor.Request) -> EventLoopFuture<Void> {
        request.eventLoop.makeSucceededFuture(Void())
            .map {
                request.enterRequestContext(with: self) { `guard` in
                    `guard`.check()
                }
            }
    }
}


extension Guard {
    func executeGuardCheck(on request: Vapor.Request) -> EventLoopFuture<Void> {
        request.enterRequestContext(with: self) { `guard` in
                `guard`.check()
            }
            .hop(to: request.eventLoop)
            .map { _ in }
    }
}


struct AnyGuard {
    let guardType: ObjectIdentifier
    private var _executeGuardCheck: (Vapor.Request) -> EventLoopFuture<Void>
    
    init<G: Guard>(_ guard: G) {
        guardType = ObjectIdentifier(G.self)
        _executeGuardCheck = `guard`.executeGuardCheck
    }
    
    init<G: SyncGuard>(_ guard: G) {
        guardType = ObjectIdentifier(G.self)
        _executeGuardCheck = `guard`.executeGuardCheck
    }
    
    func executeGuardCheck(on request: Vapor.Request) -> EventLoopFuture<Void> {
        _executeGuardCheck(request)
    }
}
