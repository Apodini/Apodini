protocol AnyTupleComponent {
    var components: [AnyComponent] { get }
}

struct TupleComponent<T>: Component, AnyTupleComponent {
    private let tuple: T
    
    #warning("Question: I suspect I will need to iterate over the elements in a TupleComponent as part of the TreeParser implementation. What would be the best way to iterate over the components? I can not return Components as Component can only be returned as a generic contraint.")
    var components: [AnyComponent] {
        Mirror(reflecting: tuple)
            .children
            .map { child in
                guard let anyComponent = child.value as? AnyComponent else {
                    fatalError("TupleComponent must contain a tuple of Components")
                }
                
                return anyComponent
            }
    }

    init(_ tuple: T) {
        self.tuple = tuple
    }
}
