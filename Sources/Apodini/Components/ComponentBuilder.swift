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
    
    public static func buildBlock<
        C0: Component,
        C1: Component
    >(_ c0: C0, _ c1: C1) -> AnyComponentCollection {
        AnyComponentCollection(
            [
                AnyComponent(c0),
                AnyComponent(c1)
            ]
        )
    }
    
    public static func buildBlock<
        C0: Component,
        C1: Component,
        C2: Component
    >(_ c0: C0, _ c1: C1, _ c2: C2) -> AnyComponentCollection {
        AnyComponentCollection(
            [
                AnyComponent(c0),
                AnyComponent(c1),
                AnyComponent(c2)
            ]
        )
    }
    
    public static func buildBlock<
        C0: Component,
        C1: Component,
        C2: Component,
        C3: Component
    >(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3) -> AnyComponentCollection {
        AnyComponentCollection(
            [
                AnyComponent(c0),
                AnyComponent(c1),
                AnyComponent(c2),
                AnyComponent(c3)
            ]
        )
    }
    
    public static func buildBlock<
        C0: Component,
        C1: Component,
        C2: Component,
        C3: Component,
        C4: Component
    >(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4) -> AnyComponentCollection {
        AnyComponentCollection(
            [
                AnyComponent(c0),
                AnyComponent(c1),
                AnyComponent(c2),
                AnyComponent(c3),
                AnyComponent(c4)
            ]
        )
    }
    
    public static func buildBlock<
        C0: Component,
        C1: Component,
        C2: Component,
        C3: Component,
        C4: Component,
        C5: Component
    >(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5) -> AnyComponentCollection {
        AnyComponentCollection(
            [
                AnyComponent(c0),
                AnyComponent(c1),
                AnyComponent(c2),
                AnyComponent(c3),
                AnyComponent(c4),
                AnyComponent(c5)
            ]
        )
    }
    
    public static func buildBlock<
        C0: Component,
        C1: Component,
        C2: Component,
        C3: Component,
        C4: Component,
        C5: Component,
        C6: Component
    >(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6) -> AnyComponentCollection {
        AnyComponentCollection(
            [
                AnyComponent(c0),
                AnyComponent(c1),
                AnyComponent(c2),
                AnyComponent(c3),
                AnyComponent(c4),
                AnyComponent(c5),
                AnyComponent(c6)
            ]
        )
    }
    
    public static func buildBlock<
        C0: Component,
        C1: Component,
        C2: Component,
        C3: Component,
        C4: Component,
        C5: Component,
        C6: Component,
        C7: Component
    >(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6, _ c7: C7) -> AnyComponentCollection {
        AnyComponentCollection(
            [
                AnyComponent(c0),
                AnyComponent(c1),
                AnyComponent(c2),
                AnyComponent(c3),
                AnyComponent(c4),
                AnyComponent(c5),
                AnyComponent(c6),
                AnyComponent(c7)
            ]
        )
    }
    
    public static func buildBlock<
        C0: Component,
        C1: Component,
        C2: Component,
        C3: Component,
        C4: Component,
        C5: Component,
        C6: Component,
        C7: Component,
        C8: Component
    >(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6, _ c7: C7, _ c8: C8) -> AnyComponentCollection {
        AnyComponentCollection(
            [
                AnyComponent(c0),
                AnyComponent(c1),
                AnyComponent(c2),
                AnyComponent(c3),
                AnyComponent(c4),
                AnyComponent(c5),
                AnyComponent(c6),
                AnyComponent(c7),
                AnyComponent(c8)
            ]
        )
    }
    
    public static func buildBlock<
        C0: Component,
        C1: Component,
        C2: Component,
        C3: Component,
        C4: Component,
        C5: Component,
        C6: Component,
        C7: Component,
        C8: Component,
        C9: Component
    >(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6, _ c7: C7, _ c8: C8, _ c9: C9) -> AnyComponentCollection {
        AnyComponentCollection(
            [
                AnyComponent(c0),
                AnyComponent(c1),
                AnyComponent(c2),
                AnyComponent(c3),
                AnyComponent(c4),
                AnyComponent(c5),
                AnyComponent(c6),
                AnyComponent(c7),
                AnyComponent(c8),
                AnyComponent(c9)
            ]
        )
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
