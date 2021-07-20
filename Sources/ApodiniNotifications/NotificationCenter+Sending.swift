//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
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
    @discardableResult
    public func send(notification: Notification, to devices: [Device]) -> EventLoopFuture<Void> {
        let fcmNotification = notification.transformToFCM()
        let apnsNotification = notification.transformToAPNS()
        
        return send(apnsNotification, fcmNotification, to: devices)
    }
    
    /// Batch sending a push notification with data encoded as JSON to multiple `Device`s.
    ///
    /// - Parameters:
    ///     - notification: The `Notification` to send
    ///     - data: An object conforming to `Encodable` which is used in the payload of the push notification.
    ///     - to: The receveing `Device`s of the push notification
    ///
    /// - Returns: An `EventLoopFuture` to indicate the completion of the operation.
    @discardableResult
    public func send<T: Encodable>(notification: Notification, with data: T, to devices: [Device]) -> EventLoopFuture<Void> {
        let fcmNotification = notification.transformToFCM(with: data)
        let apnsNotification = notification.transformToAPNS(with: data)
        
        return send(apnsNotification, fcmNotification, to: devices)
    }
    
    /// Sends a push notification to all devices which are subscribed to a topic.
    /// APNS `Device`s are directly addressed with the id.
    /// The broadcasting to FCM `Devices` is handled by Firebase.
    ///
    /// - Note: FCM `Device`s need to be first be subscribed to the topic over Firebase.
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
        
        return send(apnsNotification, fcmNotification, to: topic)
    }
    
    /// Sends a push notification with data as JSON to all devices which are subscribed to a topic.
    /// APNS `Device`s are directly addressed with the id.
    /// The broadcasting to FCM `Devices` is handled by Firebase.
    ///
    /// - Note: FCM `Device`s need to be first be subscribed to the topic over Firebase.
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
        
        return send(apnsNotification, fcmNotification, to: topic)
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
}

// MARK: - Private Extension

private extension NotificationCenter {
    func send(_ apnsNotification: AcmeNotification, _ fcmNotification: FCMMessageDefault, to devices: [Device]) -> EventLoopFuture<Void> {
        devices
            .map { device in
                device.type == .apns ?
                    sendAPNS(apnsNotification, to: device.id) :
                    sendFCM(fcmNotification, to: device.id)
            }
            .flatten(on: app.eventLoopGroup.next()) // Transforms EventLoopFuture<[Void]> to EventLoopFuture<Void>
    }
    
    func send(_ apnsNotification: AcmeNotification, _ fcmNotification: FCMMessageDefault, to topic: String) -> EventLoopFuture<Void> {
        getAPNSDevices(of: topic)
            .sequencedFlatMapEach { apnsDevice in // Iterates over every APNS Device
                sendAPNS(apnsNotification, to: apnsDevice.id)
            }
            .flatMap {
                sendFCM(fcmNotification, topic: topic)
            }
    }
    
    // MARK: Send to push notification providers
    @discardableResult
    func sendAPNS(_ notification: AcmeNotification, to deviceToken: String) -> EventLoopFuture<Void> {
        if isAPNSConfigured {
            return app.apns.send(notification, to: deviceToken)
        }
        return app.eventLoopGroup.future(())
    }
    
    @discardableResult
    func sendFCM(_ message: FCMMessageDefault, to deviceToken: String) -> EventLoopFuture<Void> {
        if isFCMConfigured {
            message.token = deviceToken
            return app.fcm.send(message).transform(to: ())
        }
        return app.eventLoopGroup.future(())
    }
    
    @discardableResult
    func sendFCM(_ message: FCMMessageDefault, topic: String) -> EventLoopFuture<Void> {
        if isFCMConfigured {
            message.topic = topic
            return app.fcm.send(message).transform(to: ())
        }
        return app.eventLoopGroup.future(())
    }
}
