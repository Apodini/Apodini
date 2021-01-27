import Apodini

/// Extension that defines methods that traverses properties of `Job`s.`
extension Job {
    func injectApplication(app: Application) -> Self {
        var selfCopy = self

        Apodini.apply({ (applicationInjectable: inout ApplicationInjectable) in
            applicationInjectable.inject(app: app)
        }, to: &selfCopy)
        
        return selfCopy
    }
    
    /// Activates all properties of `Job`s at once
    func activate() -> Self {
        var selfCopy = self

        apply({ (activatable: inout Activatable) in
            activatable.activate()
        }, to: &selfCopy)
        
        return selfCopy
    }
}
