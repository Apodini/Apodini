@propertyWrapper
struct Body<Element: Codable> {
    var wrappedValue: Element
    
    init() {
        fatalError("Not implemented")
    }
}
