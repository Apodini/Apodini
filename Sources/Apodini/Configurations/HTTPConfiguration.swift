//
//  HTTPConfiguration.swift
//  
//
//  Created by Tim Gymnich on 18.1.21.
//

import Foundation
import NIO

/// A `Configuration` for HTTP.
/// The configuration can be done in two ways, either via the
/// command line arguments --hostname, --port and --bind or via the
/// function `address`
public final class HTTPConfiguration: Configuration {
    enum Defaults {
        static let hostname = "0.0.0.0"
        static let port = 8080
    }
    
    enum HTTPConfigurationError: LocalizedError {
        case incompatibleFlags

        var errorDescription: String? {
            switch self {
            case .incompatibleFlags:
                return "The command line arguments for HTTPConfiguration are invalid."
            }
        }

        var recoverySuggestion: String? {
            switch self {
            case .incompatibleFlags:
                return "Example usage of HTTPConfiguration: --hostname 0.0.0.0 --port 8080 or --bind 0.0.0.0:8080"
            }
        }
    }
    
    private var address: BindAddress?
    
    /// initalize HTTPConfiguration
    public init(hostname: String? = nil, port: Int? = nil, bind: String? = nil, socketPath: String? = nil) {
        do {
            switch (hostname, port, bind, socketPath) {
            case (.none, .none, .none, .none):
                self.address = nil
            case (.none, .none, .none, .some(let socketPath)):
                self.address = .unixDomainSocket(path: socketPath)
            case (.none, .none, .some(let address), .none):
                let components = address.split(separator: ":")
                let hostname = components.first.map { String($0) }
                let port = components.last.flatMap { Int($0) }
                self.address = .hostname(hostname, port: port)
            case let (hostname, port, .none, .none):
                self.address = .hostname(hostname ?? Defaults.hostname, port: port ?? Defaults.port)
            default:
                throw HTTPConfigurationError.incompatibleFlags
            }
        } catch {
            fatalError("Cannot read http server address provided via command line. Error: \(error)")
        }
    }

    /// Configure application
    public func configure(_ app: Application) {
        if let address = self.address {
            app.http.address = address
        } else {
            app.logger.warning("No http server address configured")
        }
    }

    /// Sets the http server address
    public func address(_ address: BindAddress) -> Self {
        guard self.address == nil else {
            return self
        }
        self.address = address
        return self
    }
}
