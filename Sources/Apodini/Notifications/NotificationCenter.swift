//
//  NotificationCenter.swift
//  
//
//  Created by Alexander Collins on 12.11.20.
//

import class Vapor.Application
import struct Vapor.Abort
import Fluent
import APNS
import FCM

/// The `NotificationCenter` is responsible for push notifications in Apodini.
/// It can send messages to both APNS and FCM and also manages storing and configuring of `Device`s in a database.
///
/// A web service needs to add at least one push notification provider to the `Configuration` stored property.
/// The management of `Device`s is enabled by adding a database to the web service and using the modifier `.addNotifications()`.
///
/// The `NotificationCenter` can be used in any `Component` with the `@Environment` property wrapper.
///
/// ```
///  @Environment(\.notificationCenter) notificationCenter: NotificationCenter
/// ```
///
/// - Remark: The `NotificationCenter` is an abstraction of [APNS](https://github.com/vapor/apns) and [FCM](https://github.com/MihaelIsaev/FCM).
public class NotificationCenter {
    internal static let shared = NotificationCenter()
    internal var application: Application?
    
    private var app: Application {
        guard let app = application else {
            fatalError("The `NotificationCenter` is not configured. Please add the missing configuration to the web service.")
        }
        return app
    }
    
    /// Property to directly use the [APNS](https://github.com/vapor/apns) library.
    public var apns: Application.APNS {
        app.apns
    }
    
    /// Property to directly use the [FCM](https://github.com/MihaelIsaev/FCM) library.
    public var fcm: FCM {
        app.fcm
    }
    
    private init() { }
    
    /// Saves a `Device` to a database.
    ///
    /// - Parameter device: The `Device` to be saved.
    ///
    /// - Returns: An `EventLoopFuture` to indicate the completion of the operation.
    public func register(device: Device) -> EventLoopFuture<Void> {
        device
            .transform()
            .save(on: app.db)
            .flatMapError { _ in
                self.app.logger.error("Could not save device with id: \(device.id) to databse. It may already be stored in the database.")
                return self.app.eventLoopGroup.future(())
            }
    }
    
    /// Retrieves all `Device`s stored in the database.
    ///
    /// - Returns: An array of all stored `Device`s
    public func getAllDevices() -> EventLoopFuture<[Device]> {
        DeviceDatabaseModel
            .query(on: app.db)
            .all()
            .mapEach { $0.transform() }
    }
    
    /// Retrieves all `Device`s for `APNS` in the database.
    ///
    /// - Returns: An array of all stored `Device`s with type `apns`.
    public func getAPNSDevices() -> EventLoopFuture<[Device]> {
        DeviceDatabaseModel
            .query(on: app.db)
            .filter(\.$type == .apns)
            .all()
            .mapEach { $0.transform() }
    }
    
    /// Retrieves all `Device`s for `FCM` in the database.
    ///
    /// - Returns: An array of all stored `Device`s with type `fcm`.
    public func getFCMDevices() -> EventLoopFuture<[Device]> {
        DeviceDatabaseModel
            .query(on: app.db)
            .filter(\.$type == .fcm)
            .all()
            .mapEach { $0.transform() }
    }
    
    /// Retrieves all `Device`s which are subscribed to a topic.
    ///
    /// - Parameter of: The topic of a `Device`
    ///
    /// - Returns: An array of all stored `Device`s
    public func getDevices(of topic: String) -> EventLoopFuture<[Device]> {
        DeviceDatabaseModel
            .query(on: app.db)
            .all()
            .mapEachCompact { device in
                device.topics.contains(topic) ? device.transform() : nil
            }
    }
    
    /// Adds a variadic number of  topic to one or more `Device`s.
    ///
    /// - Parameters:
    ///     - topics: Variadic number of topics
    ///     - to: Variadic number of `Device`s
    ///
    /// - Returns: An `EventLoopFuture` to indicate the completion of the operation.
    @discardableResult
    public func addTopics(_ topics: String..., to device: Device) -> EventLoopFuture<Void> {
        DeviceDatabaseModel
            .find(device.id, on: app.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { device -> EventLoopFuture<Void> in
                device.topics.append(contentsOf: topics)
                return device.save(on: self.app.db)
            }
    }
    
    /// Deletes a stored `Device`.
    ///
    /// - Parameter device: The `Device` to delete
    ///
    /// - Returns: An `EventLoopFuture` to indicate the completion of the operation.
    @discardableResult
    public func delete(device: Device) -> EventLoopFuture<Void> {
        DeviceDatabaseModel
            .find(device.id, on: app.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.delete(on: self.app.db) }
    }
    
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

enum NotificationCenterEnvironmentKey: EnvironmentKey {
    static var defaultValue = NotificationCenter.shared
}

extension EnvironmentValues {
    /// The environment value to use the `NotificationCenter` in a `Component`.
    public var notificationCenter: NotificationCenter {
        get { self[NotificationCenterEnvironmentKey.self] }
        set { self[NotificationCenterEnvironmentKey.self] = newValue }
    }
}
