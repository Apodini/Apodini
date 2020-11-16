//
//  NotificationCenter.swift
//  
//
//  Created by Alexander Collins on 12.11.20.
//

import Foundation
import Vapor
import APNS
import JWTKit


public enum APNSAuthentication {
    case pem(pemPath: String, privateKeyPath: String?, pemPassword: [UInt8]? = nil)
    case p8(path: String, keyIdentifier: JWTKit.JWKIdentifier, teamIdentifier: String)
}

// App configuration needs to be changed because of app instance
public class NotificationCenter {
    private let app: Application
    
    init(_ app: Application) {
        self.app = app
    }
    
    @discardableResult
    public func send<T>(notification: Apodini.Notification<T>, device: Device) -> EventLoopFuture<Void> {
        return app.apns.send(notification, to: device.deviceID)
    }
    
    public func apnsSetup(authentication: APNSAuthentication, topic: String, environment: APNSwiftConfiguration.Environment) throws {
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
    }
}

extension Apodini.Server {
    public typealias ApodiniAPNS = Vapor.Request.APNS
}
