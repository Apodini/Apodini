//
//  File.swift
//  
//
//  Created by Alexander Collins on 22.12.20.
//

import NIO
import FCM

/// This extension includes methods to send push notifications to `APNS` and `FCM`.
extension NotificationCenter {
    /// Sends a push notification to either APNS or FCM based on the type of the `Device`.
    ///
    /// - Parameters:
    ///     - notification: The `Notification` to send
    ///     - to: The receveing `Device` of the push notification
    ///
    /// - Returns: An `EventLoopFuture` to indicate the completion of the operation.
    @discardableResult
    public func send(notification: Notification, to device: Device) -> EventLoopFuture<Void> {
        if device.type == .apns {
            return sendAPNS(notification.transformToAPNS(), to: device.id)
        } else {
            return sendFCM(notification.transformToFCM(), to: device.id)
        }
    }
    
    /// Sends a push notification with data encoded as JSON to either APNS or FCM based on the type of the `Device`.
    ///
    /// - Parameters:
    ///     - notification: The `Notification` to send
    ///     - data: An object conforming to `Encodable` which is used in the payload of the push notification.
    ///     - to: The receveing `Device` of the push notification
    ///
    /// - Returns: An `EventLoopFuture` to indicate the completion of the operation.
    @discardableResult
    public func send<T: Encodable>(notification: Notification, with data: T, to device: Device) -> EventLoopFuture<Void> {
        if device.type == .apns {
            return sendAPNS(notification.transformToAPNS(with: data), to: device.id)
        } else {
            return sendFCM(notification.transformToFCM(with: data), to: device.id)
        }
    }
    
    /// Batch sending a push notification to multiple `Device`s.
    ///
    /// - Parameters:
    ///     - notification: The `Notification` to send
    ///     - to: The receveing `Device`s of the push notification
    public func send(notification: Notification, to devices: [Device]) {
        let fcmNotification = notification.transformToFCM()
        let apnsNotification = notification.transformToAPNS()
        
        for device in devices {
            if device.type == .apns {
                sendAPNS(apnsNotification, to: device.id)
            } else {
                sendFCM(fcmNotification, to: device.id)
            }
        }
    }
    
    /// Batch sending a push notification with data encoded as JSON to multiple `Device`s.
    ///
    /// - Parameters:
    ///     - notification: The `Notification` to send
    ///     - data: An object conforming to `Encodable` which is used in the payload of the push notification.
    ///     - to: The receveing `Device`s of the push notification
    ///
    /// - Returns: An `EventLoopFuture` to indicate the completion of the operation.
    public func send<T: Encodable>(notification: Notification, with data: T, to devices: [Device]) {
        let fcmNotification = notification.transformToFCM(with: data)
        let apnsNotification = notification.transformToAPNS(with: data)
        
        for device in devices {
            if device.type == .apns {
                sendAPNS(apnsNotification, to: device.id)
            } else {
                sendFCM(fcmNotification, to: device.id)
            }
        }
    }
    
    /// Sends a push notification to all devices which are subscribed to a topic.
    /// APNS `Device`s are directly addressed with the id.
    /// The broadcasting to FCM `Devices` is handled by Firebase.
    ///
    /// - Parameters:
    ///     - notification: The `Notification` to send
    ///     - to: The subscribed topic of `Device`s
    ///
    /// - Returns: An `EventLoopFuture` to indicate the completion of the operation.
    @discardableResult
    public func send(notification: Notification, to topic: String) -> EventLoopFuture<Void> {
        let fcmNotification = notification.transformToFCM()
        let apnsNotification = notification.transformToAPNS()
        
        return getDevices(of: topic)
            .flatMap { devices -> EventLoopFuture<Void> in
                for device in devices {
                    self.sendAPNS(apnsNotification, to: device.id)
                }
                return self.sendFCM(fcmNotification, topic: topic)
            }
    }
    
    /// Sends a push notification with data as JSON to all devices which are subscribed to a topic.
    /// APNS `Device`s are directly addressed with the id.
    /// The broadcasting to FCM `Devices` is handled by Firebase.
    ///
    /// - Parameters:
    ///     - notification: The `Notification` to send
    ///     - data: An object conforming to `Encodable` which is used in the payload of the push notification.
    ///     - to: The subscribed topic of `Device`s
    ///
    /// - Returns: An `EventLoopFuture` to indicate the completion of the operation.
    @discardableResult
    public func send<T: Encodable>(notification: Notification, with data: T, to topic: String) -> EventLoopFuture<Void> {
        let fcmNotification = notification.transformToFCM(with: data)
        let apnsNotification = notification.transformToAPNS(with: data)
        
        return getDevices(of: topic)
            .flatMap { devices -> EventLoopFuture<Void> in
                for device in devices {
                    self.sendAPNS(apnsNotification, to: device.id)
                }
                return self.sendFCM(fcmNotification, topic: topic)
            }
    }
    
    /// Sends a silent push notification with only data as JSON and no alert to a specific `Device`.
    ///
    /// - Parameters:
    ///     - data: An object conforming to `Encodable` which is used in the payload of the push notification.
    ///     - to: The receveing `Device`s of the push notification.
    ///
    /// - Returns: An `EventLoopFuture` to indicate the completion of the operation.
    @discardableResult
    public func send<T: Encodable>(data: T, to device: Device) -> EventLoopFuture<Void> {
        send(notification: Notification(), with: data, to: device)
    }
    
    /// Sends a silent push notification with only data as JSON to all `Device`s which are subscribed to a topic.
    ///
    /// - Parameters:
    ///     - data: An object conforming to `Encodable` which is used in the payload of the push notification.
    ///     - to: The subscribed topic of `Device`s.
    ///
    /// - Returns: An `EventLoopFuture` to indicate the completion of the operation.
    @discardableResult
    public func send<T: Encodable>(data: T, to topic: String) -> EventLoopFuture<Void> {
        send(notification: Notification(), with: data, to: topic)
    }
    
    @discardableResult
    private func sendAPNS(_ notification: AcmeNotification, to deviceToken: String) -> EventLoopFuture<Void> {
        apns.send(notification, to: deviceToken)
    }
    
    @discardableResult
    private func sendFCM(_ message: FCMMessageDefault, to deviceToken: String) -> EventLoopFuture<Void> {
        message.token = deviceToken
        return fcm.send(message).transform(to: ())
    }
    
    @discardableResult
    private func sendFCM(_ message: FCMMessageDefault, topic: String) -> EventLoopFuture<Void> {
        message.topic = topic
        return fcm.send(message).transform(to: ())
    }
}
