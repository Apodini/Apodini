//
//  HTTPConfiguration.swift
//  
//
//  Created by Tim Gymnich on 18.1.21.
//

import Foundation
import NIO
@_implementationOnly import ConsoleKit

/// A `Configuration` for HTTP.
/// The configuration can be done in two ways, either via the
/// command line arguments --hostname, --port and --bind or via the
/// function `address`
public class HTTPConfiguration: Configuration {
    private var address: BindAddress?

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

    /// initalize HTTPConfiguration
    public convenience init() {
        self.init(arguments: CommandLine.arguments)
    }

    init(arguments: [String]) {
        do {
            var commandInput = CommandInput(arguments: arguments)
            self.address = try detect(from: &commandInput)
        } catch {
            print(error)
        }
    }

    func detect(from commandInput: inout CommandInput) throws -> BindAddress? {
        struct Signature: CommandSignature {
            @Option(name: "hostname", short: "H", help: "Set the hostname the server will run on.")
            var hostname: String?

            @Option(name: "port", short: "p", help: "Set the port the server will run on.")
            var port: Int?

            @Option(name: "bind", short: "b", help: "Convenience for setting hostname and port together.")
            var bind: String?

            @Option(name: "unix-socket", short: nil, help: "Set the path for the unix domain socket file the server will bind to.")
            var socketPath: String?
        }

        let signature = try Signature(from: &commandInput)

        switch (signature.hostname, signature.port, signature.bind, signature.socketPath) {
        case (.none, .none, .none, .none):
            return nil
        case (.none, .none, .none, .some(let socketPath)):
            return .unixDomainSocket(path: socketPath)
        case (.none, .none, .some(let address), .none):
            let hostname = address.split(separator: ":").first.flatMap(String.init)
            let port = address.split(separator: ":").last.flatMap(String.init).flatMap(Int.init)
            return .hostname(hostname, port: port)
        case let (hostname, port, .none, .none):
            return .hostname(hostname, port: port)
        default: throw HTTPConfigurationError.incompatibleFlags
        }
    }

    /// Configure application
    public func configure(_ app: Application) {
        if let address = address {
            app.http.address = address
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
