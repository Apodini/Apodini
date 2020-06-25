struct HTTPTypeModifier<ModifiedComponent: Component>: Modifier {
    let component: ModifiedComponent
    let httpType: HTTPType
    
    
    init(_ component: ModifiedComponent, httpType: HTTPType) {
        self.component = component
        self.httpType = httpType
    }
    
    
    func visit<V>(_ visitor: inout V) where V : Visitor {
        visitor.addContext(label: "httpType", httpType)
        component.visit(&visitor)
    }
}


extension Component {
    func httpType(_ httpType: HTTPType) -> some Component {
        HTTPTypeModifier(self, httpType: httpType)
    }
}
