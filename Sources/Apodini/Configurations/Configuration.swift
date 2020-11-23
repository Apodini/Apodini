import NIO
import Vapor

/// `Configuration`s are used to register services to Apodini.
/// Each `Configuration` handles different kinds of services.
public protocol Configuration {
    /// The type of a `Configuration` which can be a composition of different `Configurations`
    associatedtype Config: Configuration = Never
    
    /// The content of a `Configuration` which can contain other `Configuration`s.
    @ConfigurationBuilder var configuration: Self.Config { get }
    
    /// A method that handles the configuration of a service which is called by the `main` function.
    ///
    /// - Parameter app: The `Vapor.Application` which is used to register the configuration in Apodini
    func configure(_ app: Application)
}


extension Never: Configuration {
    public typealias Config = Never
    
    // swiftlint:disable:next unavailable_function
    public func configure(_ app: Application) {
        fatalError("should not happen")
    }
    
    public var configuration: Never {
        fatalError("should not happen")
    }
}


extension Configuration where Self.Config == Never {
    /// Used to capture an error
    public var configuration: Never {
        fatalError("should not happen")
    }
}


extension Configuration {
    // swiftlint:disable:next unavailable_function missing_docs
    public func configure(_ app: Application) {
        fatalError("should not happen")
    }
}


extension Configuration {
    func configurable(by configurator: Configurator) {
        if let configurable = self as? Configurable {
            configurable.configurable(by: configurator)
        } else if Self.Config.self != Never.self {
            configuration.configurable(by: configurator)
        } else {
            configurator.register(configuration: self)
        }
    }
}


public protocol ConfigurationCollection: Configuration { }


public struct EmptyConfiguration: Configuration {
    public func configure(_ app: Application) { }
    
    public init() { }
}
