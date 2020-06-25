class API<Content: Component>: Component {
    let version: Int
    let content: Content
    
    init(version: Int, @ComponentBuilder content: () -> Content) {
        self.version = version
        self.content = content()
    }
}
