import APNS
import JWTKit

/// A `Configuration` used for APNS authentication
public struct APNSConfiguration: Configuration {
    private let authentication: APNSAuthentication
    private let topic: String
    private let environment: APNSwiftConfiguration.Environment
    
    
    /// Creates a new configuration for APNS
    ///
    /// - Parameters:
    ///     - authentication: The APNS authentication
    ///     - topic: The Bundle identifier of your iOS application
    ///     - environment: Specifies the APNS environment
    public init(_ authentication: APNSAuthentication, topic: String, environment: APNSwiftConfiguration.Environment) {
        self.authentication = authentication
        self.topic = topic
        self.environment = environment
    }
    
    public func configure(_ app: Application) {
        do {
            switch authentication {
            case let .pem(pemPath, privateKeyPath, pemPassword):
                app.apns.configuration = try .init(
                    authenticationMethod: .tls(
                        privateKeyPath: privateKeyPath ?? pemPath,
                        pemPath: pemPath,
                        pemPassword: pemPassword
                    ),
                    topic: topic,
                    environment: environment
                )
            case let .p8(path, keyIdentifier, teamIdentifier):
                app.apns.configuration = try .init(
                    authenticationMethod: .jwt(
                        key: .private(filePath: path),
                        keyIdentifier: keyIdentifier,
                        teamIdentifier: teamIdentifier
                    ),
                    topic: topic,
                    environment: environment
                )
            }
        } catch {
            fatalError("Error setting up APNS: \(error)")
        }
        NotificationCenter.shared.application = app
    }
}


// swiftlint:disable discouraged_optional_collection
/// An enum representing different options for APNS authentication
public enum APNSAuthentication {
    /// APNS authentication using the `.pem` file format
    ///
    /// - Parameters:
    ///     - pemPath: The path to your `.pem` file
    ///     - privateKeyPath: The path to your private key
    ///     - pemPassword: The password for the private key
    case pem(pemPath: String, privateKeyPath: String? = nil, pemPassword: [UInt8]? = nil)
    /// APNS authentication using the `.p8` file format
    ///
    /// - Parameters:
    ///     - path: The path to your `.p8` file
    ///     - keyIdentifier: The key ID of the `.p8` file
    ///     - teamIdentifier: The team ID of your Apple Developer Account
    case p8(path: String, keyIdentifier: JWTKit.JWKIdentifier, teamIdentifier: String)
}
// swiftlint:enable discouraged_optional_collection
