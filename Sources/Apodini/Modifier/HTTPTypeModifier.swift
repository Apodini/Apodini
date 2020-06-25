#warning("Question 2.1: Some modifiers can only be applied to Text in SwiftUI and seem to be defined as part of the Text struct and return a Text. Do these modifiers adapt properties of a Text? Font e.g. can be passed down a group. Is this functionality located in the View Tree parsing? ... How are modifications using modifiers stored? Just in the view tree and parsed every time? Do some modifiers, e.g., for Text specific modifiers, adjust a Text struct? Or create a new Text and copy previous modifications over?")
#warning("Question 2.2: What would be the best way to restrict a modifier to a particular group of Components? A protocol they all internally conform to?")
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
