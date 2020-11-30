//
//  NotificationCenter.swift
//  
//
//  Created by Alexander Collins on 12.11.20.
//

import Vapor
import APNS
import FCM

// App configuration needs to be changed because of app instance
public class NotificationCenter {
    public static let shared = NotificationCenter()
    public var app: Application?
    private var devices: [Device] = []
    
    init() {
        
    }
    
    public func register(_ device: Device) {
        devices.append(device)
    }
    
    public func getDevices() -> [Device] {
        return devices
    }
    
    @discardableResult
    public func send(notification: Notification, to device: Device) -> EventLoopFuture<Void> {
        sendAPNS(notification.alert, to: device.deviceID)
    }
    
    public func send(notification: Notification, to devices: [Device]) {
        for device in devices {
            sendAPNS(notification.alert, to: device.deviceID)
        }
    }
    
    public func send(notification: Notification, to subscription: String) {
        for device in devices {
            if let topics = device.topics, topics.contains(subscription) {
                if (device.type == .apns) {
                    sendAPNS(notification.alert, to: device.deviceID)
                } else {
                    sendFCM(notification.alert, to: device.deviceID)
                }
            }
        }
    }
    
    @discardableResult
    private func sendAPNS(_ alert: Alert, to deviceToken: String) -> EventLoopFuture<Void> {
        guard let app = app else {
            fatalError("Notification Center not configured")
        }
        return app.apns.send(APNSwiftAlert(title: alert.title, body: alert.body), to: deviceToken)
    }
    
    @discardableResult
    private func sendFCM(_ alert: Alert, to deviceToken: String) -> EventLoopFuture<String> {
        guard let app = app else {
            fatalError("Notification Center not configured")
        }
        return app.fcm.send(.init(token: deviceToken, notification: FCMNotification(title: alert.title, body: alert.body)))
    }
}


extension Apodini.WebService {
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
