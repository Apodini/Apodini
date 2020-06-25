@_functionBuilder
public struct ComponentBuilder {
    static func buildBlock<Content>(_ content: Content) -> Content where Content: Component {
        content
    }
    
    static func buildBlock<C0, C1>(_ c0: C0, _ c1: C1) -> TupleComponent<(C0, C1)> where C0: Component, C1: Component {
        TupleComponent((c0, c1))
    }
}
