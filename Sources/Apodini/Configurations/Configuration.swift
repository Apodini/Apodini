/// `Configuration`s are used to register services to Apodini.
/// Each `Configuration` handles different kinds of services.
public protocol Configuration {
    /// A method that handles the configuration of a service which is called by the `main` function.
    ///
    /// - Parameter
    ///    - app: The `Vapor.Application` which is used to register the configuration in Apodini
    ///    - semanticModel: The `SemanticModelBuilder` where the services are registered
    func configure(_ app: Application, _ semanticModel: SemanticModelBuilder?)
}

/// This protocol is used by the `WebService` to declare `Configuration`s in an instance
public protocol ConfigurationCollection {
    /// This stored property defines the `Configuration`s of the `WebService`
    @ConfigurationBuilder var configuration: Configuration { get }
}


extension ConfigurationCollection {
    /// The default configuration is an `EmptyConfiguration`
    @ConfigurationBuilder public var configuration: Configuration {
        EmptyConfiguration()
    }
}


public struct EmptyConfiguration: Configuration {
    public func configure(_ app: Application, _ semanticModel: SemanticModelBuilder? = nil) { }
    
    public init() { }
}


extension Array: Configuration where Element == Configuration {
    public func configure(_ app: Application, _ semanticModel: SemanticModelBuilder? = nil) {
        let semanticModelBuilder = (semanticModel != nil) ? semanticModel : SemanticModelBuilder(app)
        
        forEach {
            $0.configure(app, semanticModelBuilder)
        }
    }
}
