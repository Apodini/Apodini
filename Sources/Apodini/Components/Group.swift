struct Group<Content: Component>: Component {
    private let pathComponents: [PathComponent]
    let content: Content
    
    
    init(_ pathComponents: PathComponent...,
         @ComponentBuilder content: () -> Content) {
        self.pathComponents = pathComponents
        self.content = content()
    }
    
    
    func visit<V>(_ visitor: inout V) where V: Visitor {
        visitor.enter(self)
        visitor.addContext(label: "pathComponents", pathComponents)
        content.visit(&visitor)
        visitor.exit(self)
    }
}
