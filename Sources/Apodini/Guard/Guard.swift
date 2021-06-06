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
    
    /// Resets all guards for the modified `Component`
    public func resetGuards() -> DelegateFilterModifier<Self> {
        self.reset(using: GuardFilter())
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

internal struct GuardingHandler<D, G>: Handler where D: Handler, G: Guard {
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


struct SyncGuardingHandler<D, G>: Handler where D: Handler, G: SyncGuard {
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


private protocol SomeGuardInitializer { }

extension GuardingHandlerInitializer: SomeGuardInitializer { }

extension SyncGuardingHandlerInitializer: SomeGuardInitializer { }


private struct GuardFilter: DelegateFilter {
    func callAsFunction<I>(_ initializer: I) -> Bool where I : AnyDelegatingHandlerInitializer {
        if initializer is SomeGuardInitializer {
            return false
        }
        return true
    }
}
