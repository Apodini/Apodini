//
//  GuardModifier.swift
//  
//
//  Created by Paul Schmiedmayer on 6/27/20.
//

import NIO


private struct ResetGuard: Guard {
    public func check(_ request: Request) -> EventLoopFuture<Void> {
        fatalError("The ResetGuard is used to reset the Guards for a Component and should never be called")
    }
}

public struct GuardContextKey: ContextKey {
    public static var defaultValue: [Guard] = []
    
    public static func reduce(value: inout [Guard], nextValue: () -> [Guard]) {
        let nextGuards = nextValue()
        for `guard` in nextGuards {
            if `guard`.self is ResetGuard {
                value = []
            } else {
                value.append(`guard`)
            }
        }
    }
}


public struct GuardModifier<C: Component>: Modifier {
    let component: C
    let `guard`: Guard
    
    
    init(_ component: C, guard: Guard) {
        self.component = component
        self.guard = `guard`
    }
    
    
    public func visit<V>(_ visitor: inout V) where V : Visitor {
        visitor.addContext(GuardContextKey.self, value: [`guard`], scope: .environment)
        component.visit(&visitor)
    }
    
    public func handle(_ request: Request) -> EventLoopFuture<C.Response> {
        `guard`.checkInContext(of: request)
            .flatMap {
                component.handleInContext(of: request)
            }
    }
}


extension Component {
    public func `guard`(_ guard: Guard) -> GuardModifier<Self> {
        GuardModifier(self, guard: `guard`)
    }
    
    public func resetGuards() -> GuardModifier<Self> {
        GuardModifier(self, guard: ResetGuard())
    }
}
