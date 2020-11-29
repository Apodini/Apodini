//
//  NotificationCenter.swift
//  
//
//  Created by Alexander Collins on 12.11.20.
//

import Vapor
import APNS

// App configuration needs to be changed because of app instance
public class NotificationCenter {
    public static let shared = NotificationCenter()
    public var app: Application?
    
    init() {
        
    }
    
    @discardableResult
    public func send(notification: APNSwift.APNSwiftAlert, device: Device) -> EventLoopFuture<Void> {
        guard let app = app else {
            fatalError("Notification Center not configured")
        }
        return app.apns.send(notification, to: device.deviceID)
    }
}


extension Apodini.Server {
    public typealias ApodiniAPNS = Vapor.Request.APNS
}

enum NotificationCenterEnvironmentKey: EnvironmentKey {
    static var defaultValue: NotificationCenter = NotificationCenter.shared
}

extension EnvironmentValues {
    public var notificationCenter: NotificationCenter {
        get { self[NotificationCenterEnvironmentKey.self] }
        set { self[NotificationCenterEnvironmentKey.self] = newValue }
    }
}
