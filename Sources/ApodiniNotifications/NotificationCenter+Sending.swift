//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import NIO


/// This extension includes methods to send push notifications to `APNS`.
extension NotificationCenter {
    /// Sends a push notification to APNS.
    ///
    /// - Parameters:
    ///     - notification: The `Notification` to send
    ///     - to: The receveing `Device` of the push notification
    ///
    /// - Returns: An `EventLoopFuture` to indicate the completion of the operation.
    @discardableResult
    public func send(notification: Notification, to device: Device) -> EventLoopFuture<Void> {
        switch device.type {
        case .apns:
            return sendAPNS(notification.transformToAPNS(), to: device.id)
        }
    }
    
    /// Sends a push notification with data encoded as JSON to  APNS.
    ///
    /// - Parameters:
    ///     - notification: The `Notification` to send
    ///     - data: An object conforming to `Encodable` which is used in the payload of the push notification.
    ///     - to: The receveing `Device` of the push notification
    ///
    /// - Returns: An `EventLoopFuture` to indicate the completion of the operation.
    @discardableResult
    public func send<T: Encodable>(notification: Notification, with data: T, to device: Device) -> EventLoopFuture<Void> {
        switch device.type {
        case .apns:
            return sendAPNS(notification.transformToAPNS(with: data), to: device.id)
        }
    }
    
    /// Batch sending a push notification to multiple `Device`s.
    ///
    /// - Parameters:
    ///     - notification: The `Notification` to send
    ///     - to: The receveing `Device`s of the push notification
    @discardableResult
    public func send(notification: Notification, to devices: [Device]) -> EventLoopFuture<Void> {
        let apnsNotification = notification.transformToAPNS()
        return send(apnsNotification, to: devices)
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
        let apnsNotification = notification.transformToAPNS(with: data)
        return send(apnsNotification, to: devices)
    }
    
    /// Sends a push notification to all devices which are subscribed to a topic.
    /// APNS `Device`s are directly addressed with the id.
    ///
    /// - Parameters:
    ///     - notification: The `Notification` to send
    ///     - to: The subscribed topic of `Device`s
    ///
    /// - Returns: An `EventLoopFuture` to indicate the completion of the operation.
    @discardableResult
    public func send(notification: Notification, to topic: String) -> EventLoopFuture<Void> {
        let apnsNotification = notification.transformToAPNS()
        return send(apnsNotification, to: topic)
    }
    
    /// Sends a push notification with data as JSON to all devices which are subscribed to a topic.
    /// APNS `Device`s are directly addressed with the id.
    ///
    /// - Parameters:
    ///     - notification: The `Notification` to send
    ///     - data: An object conforming to `Encodable` which is used in the payload of the push notification.
    ///     - to: The subscribed topic of `Device`s
    ///
    /// - Returns: An `EventLoopFuture` to indicate the completion of the operation.
    @discardableResult
    public func send<T: Encodable>(notification: Notification, with data: T, to topic: String) -> EventLoopFuture<Void> {
        let apnsNotification = notification.transformToAPNS(with: data)
        return send(apnsNotification, to: topic)
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
    func send(_ apnsNotification: AcmeNotification, to devices: [Device]) -> EventLoopFuture<Void> {
        devices.map { device in
            switch device.type {
            case .apns:
                return sendAPNS(apnsNotification, to: device.id)
            }
        }
        .flatten(on: app.eventLoopGroup.next()) // Transforms EventLoopFuture<[Void]> to EventLoopFuture<Void>
    }
    
    func send(_ apnsNotification: AcmeNotification, to topic: String) -> EventLoopFuture<Void> {
        getAPNSDevices(of: topic)
            .sequencedFlatMapEach { apnsDevice in // Iterates over every APNS Device
                sendAPNS(apnsNotification, to: apnsDevice.id)
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
}
