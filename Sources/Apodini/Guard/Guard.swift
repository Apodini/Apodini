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
    func check() throws
}


/// A `Guard` can be used to inspect request and guard `Component`s using the check method
public protocol Guard {
    /// The `check` method can be used to inspect incoming requests
    func check() throws -> EventLoopFuture<Void>
}


extension SyncGuard {
    func executeGuardCheck(on request: Request) -> EventLoopFuture<Void> {
        do {
            try request.enterRequestContext(with: self) { guardInstance in
                try guardInstance.check()
            }
            return request.eventLoop.makeSucceededVoidFuture()
        } catch {
            return request.eventLoop.makeFailedFuture(error)
        }
    }
}

extension SyncGuard {
    mutating func activate() {
        Apodini.activate(&self)
    }
    
    mutating func inject(app: Application) {
        Apodini.inject(app: app, to: &self)
    }
}


extension Guard {
    func executeGuardCheck(on request: Request) -> EventLoopFuture<Void> {
        do {
            return try request
                .enterRequestContext(with: self) { guardInstance in
                    try guardInstance.check()
                }
                .hop(to: request.eventLoop)
                .map { _ in }
        } catch {
            return request.eventLoop.makeFailedFuture(error)
        }
    }
}

extension Guard {
    mutating func activate() {
        Apodini.activate(&self)
    }
    
    mutating func inject(app: Application) {
        Apodini.inject(app: app, to: &self)
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
    
    mutating func inject(app: Application) {
        switch self {
        case .sync(var syncGuard):
            syncGuard.inject(app: app)
            self = .sync(syncGuard)
        case .async(var asyncGuard):
            asyncGuard.inject(app: app)
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
    
    mutating func inject(app: Application) {
        _wrapped.inject(app: app)
    }
}


extension Component {
    /// Use an asynchronous `Guard` to guard `Component`s by inspecting incoming requests
    /// - Parameter guard: The `Guard` used to inspecting incoming requests
    /// - Returns: Returns a modified `Component` protected by the asynchronous `Guard`
    public func `guard`<G: Guard>(_ guard: G) -> DelegateModifier<Self, GuardingHandlerInitializer<G, Never>> {
        DelegateModifier(self, initializer: GuardingHandlerInitializer(guard: `guard`))
    }
    
    /// Use a synchronous `SyncGuard` to guard `Component`s by inspecting incoming requests
    /// - Parameter guard: The `Guard` used to inspecting incoming requests
    /// - Returns: Returns a modified `Component` protected by the synchronous `SyncGuard`
    public func `guard`<G: SyncGuard>(_ guard: G) -> DelegateModifier<Self, SyncGuardingHandlerInitializer<G, Never>> {
        DelegateModifier(self, initializer: SyncGuardingHandlerInitializer(guard: `guard`))
    }
}

extension Handler {
    /// Use an asynchronous `Guard` to guard a `Handler` by inspecting incoming requests
    /// - Parameter guard: The `Guard` used to inspecting incoming requests
    /// - Returns: Returns a modified `Component` protected by the asynchronous `Guard`
    public func `guard`<G: Guard>(_ guard: G) -> DelegateModifier<Self, GuardingHandlerInitializer<G, Response>> {
        DelegateModifier(self, initializer: GuardingHandlerInitializer(guard: `guard`))
    }
    
    /// Use a synchronous `SyncGuard` to guard a `Handler` by inspecting incoming requests
    /// - Parameter guard: The `Guard` used to inspecting incoming requests
    /// - Returns: Returns a modified `Component` protected by the synchronous `SyncGuard`
    public func `guard`<G: SyncGuard>(_ guard: G) -> DelegateModifier<Self, SyncGuardingHandlerInitializer<G, Response>> {
        DelegateModifier(self, initializer: SyncGuardingHandlerInitializer(guard: `guard`))
    }
}

private struct GuardingHandler<D, G>: Handler where D: Handler, G: Guard {
    var guarded: Delegate<D>
    var `guard`: Delegate<G>
    
    @Environment(\.connection) var connection
    
    func handle() throws -> EventLoopFuture<D.Response> {
        try `guard`().check().flatMapThrowing { _ in
            try guarded().handle()
        }
    }
}


public struct GuardingHandlerInitializer<G: Guard, R: ResponseTransformable>: DelegatingHandlerInitializer {
    public typealias Response = R
    
    let `guard`: G
    
    public func instance<D>(for delegate: D) throws -> SomeHandler<Response> where D : Handler {
        SomeHandler<Response>(GuardingHandler(guarded: Delegate(delegate), guard: Delegate(self.guard)))
    }
}


private struct SyncGuardingHandler<D, G>: Handler where D: Handler, G: SyncGuard {
    var guarded: Delegate<D>
    var `guard`: Delegate<G>
    
    @Environment(\.connection) var connection
    
    func handle() throws -> D.Response {
        try `guard`().check()
        return try guarded().handle()
    }
}


public struct SyncGuardingHandlerInitializer<G: SyncGuard, R: ResponseTransformable>: DelegatingHandlerInitializer {
    public typealias Response = R
    
    let `guard`: G
    
    public func instance<D>(for delegate: D) throws -> SomeHandler<Response> where D : Handler {
        SomeHandler<Response>(SyncGuardingHandler(guarded: Delegate(delegate), guard: Delegate(self.guard)))
    }
}
