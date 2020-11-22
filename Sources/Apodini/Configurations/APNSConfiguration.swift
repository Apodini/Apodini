//
//  APNSConfiguration.swift
//  
//
//  Created by Alexander Collins on 18.11.20.
//

import Vapor
import APNS
import JWTKit


public struct APNSConfiguration: Configuration {
    
    private let authentication: APNSAuthentication
    private let topic: String
    private let environment: APNSwiftConfiguration.Environment
    
    
    public init(_ authentication: APNSAuthentication, topic: String, environment: APNSwiftConfiguration.Environment) {
        self.authentication = authentication
        self.topic = topic
        self.environment = environment
    }
    
    public func configure(_ app: Application) -> Bool {
        do {
        switch authentication {
        case .pem(let pemPath, let privateKeyPath, let pemPassword):
            app.apns.configuration = try .init(
                authenticationMethod: .tls(
                    privateKeyPath: privateKeyPath ?? pemPath,
                    pemPath: pemPath,
                    pemPassword: pemPassword
                ),
                topic: topic,
                environment: environment
            )
        case .p8(let path, let keyIdentifier, let teamIdentifier):
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
            fatalError("Error setting up APNS")
        }
        return true
    }
}


public enum APNSAuthentication {
    case pem(pemPath: String, privateKeyPath: String? = nil, pemPassword: [UInt8]? = nil)
    case p8(path: String, keyIdentifier: JWTKit.JWKIdentifier, teamIdentifier: String)
}
