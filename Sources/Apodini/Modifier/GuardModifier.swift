//
//  GuardModifier.swift
//  
//
//  Created by Paul Schmiedmayer on 6/27/20.
//

import Vapor


private struct ResetGuard: Guard {
    public func check(_ request: Vapor.Request) -> EventLoopFuture<Void> {
        fatalError("The ResetGuard is used to reset the Guards for a Component and should never be called")
    }
}

public typealias LazyGuard = () -> (Guard)

public struct GuardContextKey: ContextKey {
    public static var defaultValue: [LazyGuard] = []
    
    public static func reduce(value: inout [LazyGuard], nextValue: () -> [LazyGuard]) {
        let nextGuards = nextValue()
        for `guard` in nextGuards {
            if `guard`().self is ResetGuard {
                value = []
            } else {
                value.append(`guard`)
            }
        }
    }
}


public struct GuardModifier<C: Component>: Modifier {
    let component: C
    let `guard`: LazyGuard
    
    
    init(_ component: C, guard: @escaping @autoclosure LazyGuard) {
        self.component = component
        self.guard = `guard`
    }
    
    
    public func visit<V>(_ visitor: inout V) where V : Visitor {
        visitor.addContext(GuardContextKey.self, value: [`guard`], scope: .environment)
        component.visit(&visitor)
    }
    
    public func handle(_ request: Request) -> EventLoopFuture<C.Response> {
        `guard`().checkInContext(of: request)
            .flatMap {
                self.component.handleInContext(of: request)
            }
    }
}


extension Component {
    public func `guard`(_ guard: @escaping @autoclosure () -> (Guard)) -> GuardModifier<Self> {
        GuardModifier(self, guard: `guard`())
    }
    
    public func resetGuards() -> GuardModifier<Self> {
        GuardModifier(self, guard: ResetGuard())
    }
}
