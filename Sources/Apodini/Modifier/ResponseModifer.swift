protocol ResponseMediator {
    associatedtype Response
    
    init(_ response: Response)
}


struct ResponseModifier<C: Component, M: ResponseMediator>: Modifier {
    let component: C
    let mediator = M.self
    
    
    init(_ component: C, mediator: M.Type) {
        self.component = component
    }
    
    
    func visit<V>(_ visitor: inout V) where V : Visitor {
        visitor.addContext(label: "mediator", "\(mediator.self)")
        component.visit(&visitor)
    }
}


extension Component {
    func response<M: ResponseMediator>(_ modifier: M.Type) -> some Component {
        ResponseModifier(self, mediator: M.self)
    }
}
