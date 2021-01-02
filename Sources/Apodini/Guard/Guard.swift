//
//  Guard.swift
//  
//
//  Created by Paul Schmiedmayer on 6/27/20.
//

import NIO


/// A `SyncGuard` can be used to inspect request and guard `Component`s using the check method.
/// SyncGuard`s can  be used with different request-response property wrappers to inject values from incoming requests.
public protocol SyncGuard {
    /// The `check` method can be used to inspect incoming requests
    func check()
}


/// A `Guard` can be used to inspect request and guard `Component`s using the check method
public protocol Guard {
    /// The `check` method can be used to inspect incoming requests
    func check() -> EventLoopFuture<Void>
}


extension SyncGuard {
    func executeGuardCheck(on request: Request) -> EventLoopFuture<Void> {
        request.eventLoop.makeSucceededFuture(Void())
            .map {
                request.enterRequestContext(with: self) { guardInstance in
                    guardInstance.check()
                }
            }
    }
}


extension Guard {
    func executeGuardCheck(on request: Request) -> EventLoopFuture<Void> {
        request
            .enterRequestContext(with: self) { guardInstance in
                guardInstance.check()
            }
            .hop(to: request.eventLoop)
            .map { _ in }
    }
}


struct AnyGuard {
    let guardType: ObjectIdentifier
    private var _executeGuardCheck: (Request) -> EventLoopFuture<Void>

    init<G: Guard>(_ guard: G) {
        guardType = ObjectIdentifier(G.self)
        _executeGuardCheck = `guard`.executeGuardCheck
    }

    init<G: SyncGuard>(_ guard: G) {
        guardType = ObjectIdentifier(G.self)
        _executeGuardCheck = `guard`.executeGuardCheck
    }

    func executeGuardCheck(on request: Request) -> EventLoopFuture<Void> {
        _executeGuardCheck(request)
    }
}
