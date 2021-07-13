//
//  Guard.swift
//  
//
//  Created by Paul Schmiedmayer on 6/27/20.
//


/// A `Guard` can be used to inspect request and guard `Component`s using the check method
public protocol Guard {
    /// The `check` method can be used to inspect incoming requests
    func check() async throws
}

extension Component {
    /// Use an asynchronous `Guard` to guard `Component`s by inspecting incoming requests
    /// - Parameter guard: The `Guard` used to inspecting incoming requests
    /// - Returns: Returns a modified `Component` protected by the asynchronous `Guard`
    public func `guard`<G: Guard>(_ guard: G) -> DelegationModifier<Self, GuardingHandlerInitializer<G, Never>> {
        self.delegated(by: GuardingHandlerInitializer(guard: `guard`))
    }

    /// Resets all guards for the modified `Component`
    public func resetGuards() -> DelegationFilterModifier<Self> {
        self.reset(using: GuardFilter())
    }
}

extension Handler {
    /// Use an asynchronous `Guard` to guard a `Handler` by inspecting incoming requests
    /// - Parameter guard: The `Guard` used to inspecting incoming requests
    /// - Returns: Returns a modified `Component` protected by the asynchronous `Guard`
    public func `guard`<G: Guard>(_ guard: G) -> DelegationModifier<Self, GuardingHandlerInitializer<G, Response>> {
        self.delegated(by: GuardingHandlerInitializer(guard: `guard`))
    }
}

internal struct GuardingHandler<D, G>: Handler where D: Handler, G: Guard {
    let guarded: Delegate<D>
    let `guard`: Delegate<G>
    
    func handle() async throws -> D.Response {
        try await `guard`().check()
        return try await guarded().handle()
    }
}


public struct GuardingHandlerInitializer<G: Guard, R: ResponseTransformable>: DelegatingHandlerInitializer {
    public typealias Response = R
    
    let `guard`: G
    
    public func instance<D>(for delegate: D) throws -> SomeHandler<Response> where D: Handler {
        SomeHandler<Response>(GuardingHandler(guarded: Delegate(delegate), guard: Delegate(self.guard)))
    }
}


private protocol SomeGuardInitializer { }

extension GuardingHandlerInitializer: SomeGuardInitializer { }


struct GuardFilter: DelegationFilter {
    func callAsFunction<I>(_ initializer: I) -> Bool where I: AnyDelegatingHandlerInitializer {
        if initializer is SomeGuardInitializer {
            return false
        }
        return true
    }
}
