// Question: Does an modifier adjust some private properties of a View or are they all stored in the modifers and parsed in some sort of exporter?
// We have experimented a bit with a SwiftUI implementation for HTML, there each view/modifier does build up the HTML using a fancy string interpolation. How does SwiftUI do that intnally, do you have the "render/modification" code in the modifiers/views or is there an external parser/interpeter as I am aiming it to be done here?
// Question I had to constaint the type to a concrete struct ... but as far as I can see this is not desigable as e.g. the Modifier should be usable for all Components.
struct HTTPTypeModifier: ComponentModifier {
    let httpType: HTTPType
    
    func modify(content: Self.ModifiedComponent) -> some Component {
        content
    }
}

// Question: I would suspect I can specify a modifer for all components once `HTTPTypeModifier` is generic?
// But how do I e.g. constraint a modifier to e.g. only some Component (or wrapped Modifierd Component that is e.g. only applicable to components that create elements in a database?)
extension Component {
    func httpType(_ httpType: HTTPType) -> some Component {
        ModifiedComponent(modifiedComponent: self,
                          modifier: HTTPTypeModifier(httpType: httpType))
    }
}
