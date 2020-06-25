#warning("Question: How does the typealias in `ViewModifier` public interface work? From some digging around and StackOverflow I have found that there seems to be a private _ViewModifier_Content<Self> struct that is used. How would you replicate that in my implementation of a ComponentModifier? Can somehow pass a Component into a `ComponentModifierContent` but where should we go from here?")
protocol ComponentModifier {
    typealias ModifiedComponent = ComponentModifierComponent<Self>
    associatedtype Content: Component
    
    func modify(content: Self.ModifiedComponent) -> Self.Content
}


#warning("Some modifiers can only be applied to Text in SwiftUI and seem to be defined as part of the Text struct and return a Text. These modifiers adapt properties of a Text? Font e.g. can be passed down a group, this functionality is located in the View Tree parsing? ... What would be the best way to restrict a modifier to a certain group of Components? A protocol they all internally conform to?")
struct ComponentModifierComponent<V: ComponentModifier>: Component {
    init<C: Component>(_ component: C) {
        fatalError("Not implemented. And not sure how we could do that ...? I guess I can use it to only store the type information and provide some constraints on what can be done in a ComponentModifier?")
    }
}


extension ComponentModifier where ModifiedComponent == Content {
    func body(content: Self.ModifiedComponent) -> Self.Content {
        content
    }
}


#warning("Question: Is it a general workflow in SwiftUI to use a ModifiedView struct to encapsulate Views and Modifier in the view tree?")
struct ModifiedComponent<
    Content,
    ModifiedComponent: Component,
    Modifier: ComponentModifier
>: Component where Modifier.Content == Content {
    
    let modifiedComponent: ModifiedComponent
    let modifier: Modifier
    
    var content: Content {
        modifier.modify(content: ComponentModifierComponent(modifiedComponent))
    }
}
