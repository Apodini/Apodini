#warning("Question: How are modifications using modifiers stored? Just in the view tree and parsed every time? Do some modifers, e.g. for Text specific modifiers adjust a Text struct? Or creat a new one anc copy previous modifications over?")
#warning("Question: I suspect that the work of applying the modifier is located in the tree parser/exporter on the concrete plattform?")
struct HTTPTypeModifier: ComponentModifier {
    let httpType: HTTPType
    
    func modify(content: Self.ModifiedComponent) -> some Component {
        content
    }
}


extension Component {
    func httpType(_ httpType: HTTPType) -> some Component {
        ModifiedComponent(modifiedComponent: self,
                          modifier: HTTPTypeModifier(httpType: httpType))
    }
}
