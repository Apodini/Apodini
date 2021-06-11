import ArgumentParser

/// `Configuration`s are used to register services to Apodini.
/// Each `Configuration` handles different kinds of services.
public protocol Configuration {
    /// Subcommands specified by the individual exporters
    var subcommands: [ParsableCommand.Type] { get }
    
    /// A method that handles the configuration of a service which is called by the `main` function.
    ///
    /// - Parameter
    ///    - app: The `Vapor.Application` which is used to register the configuration in Apodini
    func configure(_ app: Application)
}

extension Configuration {
    public var subcommands: [ParsableCommand.Type] {
        []
    }
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
    public func configure(_ app: Application) { }
    
    public init() { }
}


extension Array: Configuration where Element == Configuration {
    public var subcommands: [ParsableCommand.Type] {
        var subcommands: [ParsableCommand.Type] = []
        forEach {
            subcommands.append(contentsOf: $0.subcommands)
        }
        return subcommands
    }
    
    public func configure(_ app: Application) {
        forEach {
            $0.configure(app)
        }
    }
}
