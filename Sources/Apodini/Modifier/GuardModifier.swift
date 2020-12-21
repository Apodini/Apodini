//
//  GuardModifier.swift
//  
//
//  Created by Paul Schmiedmayer on 6/27/20.
//

@_implementationOnly import Runtime


private struct ResetGuard: SyncGuard {
    func check() {
        fatalError("The ResetGuard is used to reset the Guards for a Component and should never be called")
    }
}

typealias LazyGuard = () -> (AnyGuard)

struct GuardContextKey: ContextKey {
    static var defaultValue: [LazyGuard] = []
    
    static func reduce(value: inout [LazyGuard], nextValue: () -> [LazyGuard]) {
        let nextGuards = nextValue()
        for `guard` in nextGuards {
            if `guard`().guardType == ObjectIdentifier(ResetGuard.self) {
                value = []
            } else {
                value.append(`guard`)
            }
        }
    }
}


public struct GuardModifier<C: Handler>: EndpointModifier {
    public typealias ModifiedEndpoint = C
    public typealias Response = C.Response
    public typealias EndpointIdentifier = C.EndpointIdentifier
    
    let endpoint: C
    let `guard`: LazyGuard
    
    
    init<G: Guard>(_ endpoint: C, guard: @escaping () -> G) {
        precondition(((try? typeInfo(of: G.self).kind) ?? .none) == .struct, "Guard \((try? typeInfo(of: G.self).name) ?? "unknown") must be a struct")
        
        self.endpoint = endpoint
        self.guard = { AnyGuard(`guard`()) }
    }
    
    init<G: SyncGuard>(_ endpoint: C, guard: @escaping () -> G) {
        precondition(((try? typeInfo(of: G.self).kind) ?? .none) == .struct, "Guard \((try? typeInfo(of: G.self).name) ?? "unknown") must be a struct")
        
        self.endpoint = endpoint
        self.guard = { AnyGuard(`guard`()) }
    }
}

extension GuardModifier: Visitable {
    func visit(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(GuardContextKey.self, value: [`guard`], scope: .environment)
        endpoint.visit(visitor)
    }
}


extension Handler {
    /// Use an asynchronous `Guard` to guard `Component`s by inspecting incoming requests
    /// - Parameter guard: The `Guard` used to inspecting incoming requests
    /// - Returns: Returns a modified `Component` protected by the asynchronous `Guard`
    public func `guard`<G: Guard>(_ guard: @escaping @autoclosure () -> (G)) -> GuardModifier<Self> {
        GuardModifier(self, guard: `guard`)
    }
    
    /// Use a synchronous `SyncGuard` to guard `Component`s by inspecting incoming requests
    /// - Parameter guard: The `Guard` used to inspecting incoming requests
    /// - Returns: Returns a modified `Component` protected by the synchronous `SyncGuard`
    public func `guard`<G: SyncGuard>(_ guard: @escaping @autoclosure () -> (G)) -> GuardModifier<Self> {
        GuardModifier(self, guard: `guard`)
    }
    
    /// Resets all guards for the modified `Component`
    public func resetGuards() -> GuardModifier<Self> {
        GuardModifier(self, guard: { ResetGuard() })
    }
}
