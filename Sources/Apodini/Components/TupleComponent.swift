struct TupleComponent<T>: Component {
    private let tuple: T
    

    init(_ tuple: T) {
        self.tuple = tuple
    }
    
    
    func visit<V>(_ visitor: inout V) where V: Visitor {
        for child in Mirror(reflecting: tuple).children {
            guard let visitableComponent = child.value as? Visitable else {
                fatalError("TupleComponent must contain a tuple of Components")
            }
            
            visitableComponent.visit(&visitor)
        }
    }
}
