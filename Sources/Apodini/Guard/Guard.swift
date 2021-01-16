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

extension SyncGuard {
    mutating func activate() {
        Apodini.activate(&self)
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

extension Guard {
    mutating func activate() {
        Apodini.activate(&self)
    }
}

private enum SomeGuard {
    case sync(SyncGuard)
    case async(Guard)
    
    mutating func activate() {
        switch self {
        case .sync(var syncGuard):
            syncGuard.activate()
            self = .sync(syncGuard)
        case .async(var asyncGuard):
            asyncGuard.activate()
            self = .async(asyncGuard)
        }
    }
    
    func executeGuardCheck(on request: Request) -> EventLoopFuture<Void> {
        switch self {
        case .sync(let syncGuard):
            return syncGuard.executeGuardCheck(on: request)
        case .async(let asyncGuard):
            return asyncGuard.executeGuardCheck(on: request)
        }
    }
}

struct AnyGuard {
    let guardType: ObjectIdentifier
    private var _wrapped: SomeGuard

    init<G: Guard>(_ guard: G) {
        guardType = ObjectIdentifier(G.self)
        _wrapped = .async(`guard`)
    }

    init<G: SyncGuard>(_ guard: G) {
        guardType = ObjectIdentifier(G.self)
        _wrapped = .sync(`guard`)
    }

    func executeGuardCheck(on request: Request) -> EventLoopFuture<Void> {
        _wrapped.executeGuardCheck(on: request)
    }
    
    mutating func activate() {
        self._wrapped.activate()
    }
}
