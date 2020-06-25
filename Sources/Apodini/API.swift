class API<Content: Component>: Component {
    let version: Int
    let content: Content
    
    
    init(version: Int, @ComponentBuilder content: () -> Content) {
        self.version = version
        self.content = content()
    }
    
    
    func visit<V>(_ visitor: inout V) where V : Visitor {
        visitor.enter(self)
        visitor.addContext(label: "version", version)
        content.visit(&visitor)
        visitor.exit(self)
    }
}
