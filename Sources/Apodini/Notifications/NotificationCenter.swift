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
    private let app: Application
    
    init(_ app: Application) {
        self.app = app
    }
    
    @discardableResult
    public func send<T>(notification: Apodini.Notification<T>, device: Device) -> EventLoopFuture<Void> {
        return app.apns.send(notification, to: device.deviceID)
    }
    
}

extension Apodini.Server {
    public typealias ApodiniAPNS = Vapor.Request.APNS
}
