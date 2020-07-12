//
//  GuardModifier.swift
//  
//
//  Created by Paul Schmiedmayer on 6/27/20.
//

import Vapor


private struct ResetGuard: Guard {
    func check(_ request: Vapor.Request) -> EventLoopFuture<Void> {
        fatalError("The ResetGuard is used to reset the Guards for a Component and should never be called")
    }
}

typealias LazyGuard = () -> (Guard)

struct GuardContextKey: ContextKey {
    static var defaultValue: [LazyGuard] = []
    
    static func reduce(value: inout [LazyGuard], nextValue: () -> [LazyGuard]) {
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
    public typealias Response = C.Response
    
    let component: C
    let `guard`: LazyGuard
    
    
    init(_ component: C, guard: @escaping @autoclosure LazyGuard) {
        self.component = component
        self.guard = `guard`
    }
}

extension GuardModifier: Visitable {
    func visit(_ visitor: Visitor) {
        visitor.addContext(GuardContextKey.self, value: [`guard`], scope: .environment)
        component.visit(visitor)
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
