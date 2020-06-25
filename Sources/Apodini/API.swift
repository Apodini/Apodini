class API<Content: Component>: Component {
    public var content: Content
    
    init(@ComponentBuilder content: () -> Content) {
        self.content = content()
    }
}
