//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
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
        try await `guard`.instance().check()
        return try await guarded.instance().handle()
    }
}


public struct GuardingHandlerInitializer<G: Guard, R: ResponseTransformable>: DelegatingHandlerInitializer {
    public typealias Response = R
    
    let `guard`: G
    
    public func instance<D>(for delegate: D) throws -> SomeHandler<Response> where D: Handler {
        SomeHandler<Response>(GuardingHandler(guarded: Delegate(delegate, .required), guard: Delegate(self.guard, .required)))
    }
}


private protocol SomeGuardInitializer { }

extension GuardingHandlerInitializer: SomeGuardInitializer { }


struct GuardFilter: DelegationFilter {
    func callAsFunction<I>(_ initializer: I) -> Bool where I: AnyDelegatingHandlerInitializer {
        if initializer is any SomeGuardInitializer {
            return false
        }
        return true
    }
}
