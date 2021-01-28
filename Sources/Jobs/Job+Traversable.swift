import Apodini

/// Extension that defines methods that traverses properties of `Job`s.`
extension Job {
    /// Activates all properties of `Job`s at once and always keeps them activated.
    func activate() -> Self {
        var selfCopy = self

        apply({ (activatable: inout Activatable) in
            activatable.activate()
        }, to: &selfCopy)

        return selfCopy
    }
    
    /// Checks if only valid property wrappers are used with `Job`s.
    func checkPropertyWrapper() throws {
        try execute({ (_ :Environment<EnvironmentValues, Connection>) in
            throw JobErrors.requestPropertyWrapper
        }, on: self)
        
        try execute({ (_: RequestBasedPropertyWrapper) in
            throw JobErrors.requestPropertyWrapper
        }, on: self)
    }
    
    /// Subscribes to all `ObservedObject`s.
    func subscribe(configuration: JobConfiguration) {
        execute({ (observedObject: AnyObservedObject) in
            observedObject.valueDidChange = {
                observedObject.setChanged(to: true)
                // Executes the `Job` on its own event loop
                _ = configuration.scheduled?.futureResult.hop(to: configuration.eventLoop)
                observedObject.setChanged(to: false)
            }
        }, on: self)
    }
}
