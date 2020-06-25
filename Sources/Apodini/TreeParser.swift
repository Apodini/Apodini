struct TreeParser {
    func parse<C: Component>(_ component: C) {
        // Question: How can we print a "Tree Like Structure" of the components that we have in the View Tree?
        // I supsect I use the mirror API to get the the properties of a modifier to access the children to at least print the modifier as a first step?
        // Question: I can not determin if the type of a component is e.g. ComponentModifier as it can only be used as a generic constraint. What would be the best appraoch here?
        let mirror = Mirror(reflecting: component)
        // Approach Failed: Protocol 'ComponentModifier' can only be used as a generic constraint
        // if mirror.subjectType is ComponentModifier {
        
        print(component)
    }
}
