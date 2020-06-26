//
//  ComponentBuilder.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

@_functionBuilder
public struct ComponentBuilder {
    public static func buildBlock() -> EmptyComponent {
        EmptyComponent()
    }
    
    public static func buildBlock<Content>(_ content: Content) -> Content where Content: Component {
        content
    }
    
    public static func buildBlock<C0, C1>(_ c0: C0, _ c1: C1) -> TupleComponent<(C0, C1)> where C0: Component, C1: Component {
        TupleComponent((c0, c1))
    }
    
    public static func buildBlock<C0, C1, C2>(_ c0: C0, _ c1: C1, _ c2: C2) -> TupleComponent<(C0, C1, C2)> where C0: Component, C1: Component, C2: Component {
        TupleComponent((c0, c1, c2))
    }
    
    public static func buildBlock<C0, C1, C2, C3>(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3) -> TupleComponent<(C0, C1, C2, C3)> where C0: Component, C1: Component, C2: Component, C3: Component {
        TupleComponent((c0, c1, c2, c3))
    }
    
    public static func buildBlock<C0, C1, C2, C3, C4>(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4) -> TupleComponent<(C0, C1, C2, C3, C4)> where C0: Component, C1: Component, C2: Component, C3: Component, C4: Component {
        TupleComponent((c0, c1, c2, c3, c4))
    }
    
    public static func buildBlock<C0, C1, C2, C3, C4, C5>(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5) -> TupleComponent<(C0, C1, C2, C3, C4, C5)> where C0: Component, C1: Component, C2: Component, C3: Component, C4: Component, C5: Component {
        TupleComponent((c0, c1, c2, c3, c4, c5))
    }
    
    public static func buildBlock<C0, C1, C2, C3, C4, C5, C6>(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6) -> TupleComponent<(C0, C1, C2, C3, C4, C5, C6)> where C0: Component, C1: Component, C2: Component, C3: Component, C4: Component, C5: Component, C6: Component {
        TupleComponent((c0, c1, c2, c3, c4, c5, c6))
    }
    
    public static func buildBlock<C0, C1, C2, C3, C4, C5, C6, C7>(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6, _ c7: C7) -> TupleComponent<(C0, C1, C2, C3, C4, C5, C6, C7)> where C0: Component, C1: Component, C2: Component, C3: Component, C4: Component, C5: Component, C6: Component, C7: Component {
        TupleComponent((c0, c1, c2, c3, c4, c5, c6, c7))
    }
    
    public static func buildBlock<C0, C1, C2, C3, C4, C5, C6, C7, C8>(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6, _ c7: C7, _ c8: C8) -> TupleComponent<(C0, C1, C2, C3, C4, C5, C6, C7, C8)> where C0: Component, C1: Component, C2: Component, C3: Component, C4: Component, C5: Component, C6: Component, C7: Component, C8: Component {
        TupleComponent((c0, c1, c2, c3, c4, c5, c6, c7, c8))
    }
    
    public static func buildBlock<C0, C1, C2, C3, C4, C5, C6, C7, C8, C9>(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6, _ c7: C7, _ c8: C8, _ c9: C9) -> TupleComponent<(C0, C1, C2, C3, C4, C5, C6, C7, C8, C9)> where C0: Component, C1: Component, C2: Component, C3: Component, C4: Component, C5: Component, C6: Component, C7: Component, C8: Component, C9: Component {
        TupleComponent((c0, c1, c2, c3, c4, c5, c6, c7, c8, c9))
    }
    
    public static func buildEither<C: Component>(first: C) -> C {
        first
    }
    
    public static func buildEither<C: Component>(second: C) -> C {
        second
    }
    
    public static func buildIf<C: Component>(_ component: C?) -> C? {
        component
    }
}
