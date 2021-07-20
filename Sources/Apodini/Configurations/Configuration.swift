//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

/// `Configuration`s are used to register services to Apodini.
/// Each `Configuration` handles different kinds of services.
public protocol Configuration {
    /// A method that handles the configuration of a service which is called by the `main` function.
    ///
    /// - Parameter
    ///    - app: The `Vapor.Application` which is used to register the configuration in Apodini
    func configure(_ app: Application)
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
    public func configure(_ app: Application) {
        forEach {
            $0.configure(app)
        }
    }
}
