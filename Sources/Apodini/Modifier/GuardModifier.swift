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
        value.append(contentsOf: nextValue())
    }
}

extension Array where Element == LazyGuard {
    /// The array of `LazyGuard` contains all `Guard`s that have accumalated over the parsing of the DSL
    /// The developer has the option to reset any previously collected `Guard`s using the `resetGuards()` modifier that appends a `ResetGuard`
    /// This property filters out all guards that have been applied since the last `ResetGuard` and discards all previously collected `Guard`s and the `ResetGuard`
    ///
    /// Examples (the first guard was declared further to the root of the `Component` tree and registered first):
    ///
    /// `[Guard1, Guard2, ResetGuard]` -> `[]`
    ///
    /// `[Guard1, ResetGuard, Guard2]` -> `[Guard2]`
    ///
    /// `[ResetGuard, Guard1, Guard2]` -> `[Guard1, Guard2]`
    ///
    /// `[ResetGuard, Guard1, Guard2, ResetGuard]` -> `[]`
    ///
    /// `[ResetGuard, Guard1, Guard2, ResetGuard, Guard3]` -> `[Guard3]`
    var allActiveGuards: [LazyGuard] {
        guard let lastReserGuardIndex = self.lastIndex(where: { $0().guardType == ObjectIdentifier(ResetGuard.self) }) else {
            return self
        }
        return Array(self.dropFirst(lastReserGuardIndex + 1))
    }
}


public struct GuardModifier<C: Component>: Modifier {
    public typealias ModifiedComponent = C
    
    public let component: C
    let `guard`: LazyGuard
    
    public var content: some Component { EmptyComponent() }
    
    init<G: Guard>(_ component: C, guard: @escaping () -> G) {
        preconditionTypeIsStruct(G.self, messagePrefix: "Guard")
        self.component = component
        self.guard = { AnyGuard(`guard`()) }
    }
    
    init<G: SyncGuard>(_ component: C, guard: @escaping () -> G) {
        preconditionTypeIsStruct(G.self, messagePrefix: "Guard")
        self.component = component
        self.guard = { AnyGuard(`guard`()) }
    }
}

extension GuardModifier: Handler, HandlerModifier where Self.ModifiedComponent: Handler {
    public typealias Response = ModifiedComponent.Response
}

extension GuardModifier: SyntaxTreeVisitable {
    public func accept(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(GuardContextKey.self, value: [`guard`], scope: .environment)
        component.accept(visitor)
    }
}


extension Component {
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
