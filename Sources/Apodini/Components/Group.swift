struct Group<Content: Component>: Component {
    private let pathComponents: [PathComponent]
    let content: Content
    
    init(_ pathComponents: PathComponent...,
         @ComponentBuilder content: () -> Content) {
        self.pathComponents = pathComponents
        self.content = content()
    }
}
