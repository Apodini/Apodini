// swiftlint:disable first_where
//
//  NotificationCenter.swift
//  
//
//  Created by Alexander Collins on 12.11.20.
//

@_implementationOnly import struct Vapor.Abort
import Fluent
import APNS
import FCM
import NIO
import Apodini

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
    /// NotificationCenter
    internal static var shared = NotificationCenter()
    internal var application: Application?
    private var app: Application {
        guard let app = application else {
            fatalError("The `NotificationCenter` is not configured. Please add the missing configuration to the web service.")
        }
        return app
    }

    /// Property to directly use the [APNS](https://github.com/vapor/apns) library.
    internal var apns: APNSwiftClient {
        app.apns
    }
    
    /// Property to directly use the [FCM](https://github.com/MihaelIsaev/FCM) library.
    internal var fcm: FCM {
        app.fcm
    }
    
    private init() {
        // Empty intializer to create a Singleton.
    }
    
    /// Sets the `application` property if the `NotificationCenter` was correctly configured.
    internal func setup(_ application: Application) {
        if self.application == nil {
            self.application = application
        }
    }
    
    /// Saves a `Device` to a database.
    ///
    /// - Parameter device: The `Device` to be saved.
    ///
    /// - Returns: An `EventLoopFuture` to indicate the completion of the operation.
    @discardableResult
    public func register(device: Device) -> EventLoopFuture<Void> {
        let deviceDatabaseModel = device.transform()
        return deviceDatabaseModel
            .save(on: app.db)
            .flatMap { _ -> EventLoopFuture<Void> in
                if let topics = device.topics {
                    return self.attach(topics: topics, to: deviceDatabaseModel)
                } else {
                    return self.app.eventLoopGroup.future(())
                }
            }
    }
    
    /// Retrieves all `Device`s stored in the database.
    ///
    /// - Returns: An array of all stored `Device`s
    public func getAllDevices() -> EventLoopFuture<[Device]> {
        DeviceDatabaseModel
            .query(on: app.db)
            .with(\.$topics)
            .all()
            .mapEach { $0.transform() }
    }
    
    /// Retrieves a specific Device from the database.
    ///
    ///  - Parameter id: Identifier of the `Device` in the database.
    ///
    /// - Returns: The `Device` with the corresponding id.
    public func getDevice(id: String) -> EventLoopFuture<Device> {
        DeviceDatabaseModel
            .query(on: app.db)
            .filter(\.$id == id)
            .with(\.$topics)
            .first()
            .unwrap(or: Abort(.notFound))
            .map { $0.transform() }
    }
    
    /// Retrieves all `Device`s for `APNS` in the database.
    ///
    /// - Returns: An array of all stored `Device`s with type `apns`.
    public func getAPNSDevices() -> EventLoopFuture<[Device]> {
        DeviceDatabaseModel
            .query(on: app.db)
            .filter(\.$type == .apns)
            .with(\.$topics)
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
            .with(\.$topics)
            .all()
            .mapEach { $0.transform() }
    }
    
    /// Retrieves all `Device`s which are subscribed to a topic.
    ///
    /// - Parameter of: The topic of a `Device`
    ///
    /// - Returns: An array of all stored `Device`s
    public func getDevices(of topic: String) -> EventLoopFuture<[Device]> {
        Topic
            .query(on: app.db)
            .filter(\.$name == topic)
            .with(\.$devices) { devices in
                devices.with(\.$topics)
            }
            .first()
            .unwrap(or: Abort(.notFound))
            .map { topic in
                topic.devices.map {
                    $0.transform()
                }
            }
    }
    
    /// Adds a variadic number of  topic to one or more `Device`s.
    ///
    /// - Parameters:
    ///     - topics: Variadic number of topics
    ///     - to: `Device` to add topics
    ///
    /// - Returns: An `EventLoopFuture` to indicate the completion of the operation.
    @discardableResult
    public func addTopics(_ topicStrings: String..., to device: Device) -> EventLoopFuture<Void> {
        DeviceDatabaseModel
            .find(device.id, on: app.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { deviceDatabaseModel -> EventLoopFuture<Void> in
                self.attach(topics: topicStrings, to: deviceDatabaseModel)
            }
    }
    
    /// Removes a `Topic` from a `Device`.
    ///
    /// - Parameters:
    ///     - topic: The `Topic` to remove.
    ///     - from: The `Device` to remove the `Topic`.
    ///
    /// - Returns: An `EventLoopFuture` to indicate the completion of the operation.
    @discardableResult
    public func remove(topic: String, from device: Device) -> EventLoopFuture<Void> {
        Topic
            .query(on: app.db)
            .filter(\.$name == topic)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap { topicModel in
                DeviceDatabaseModel
                    .find(device.id, on: self.app.db)
                    .unwrap(or: Abort(.notFound))
                    .flatMap { deviceDatabaseModel -> EventLoopFuture<Void> in
                        deviceDatabaseModel.$topics.detach(topicModel, on: self.app.db)
                    }
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
    
    private func attach(topics: [String], to device: DeviceDatabaseModel) -> EventLoopFuture<Void> {
        topics.map {
            attach(topic: $0, to: device)
        }
        .flatten(on: app.db.eventLoop)
    }
    
    private func attach(topic topicString: String, to device: DeviceDatabaseModel) -> EventLoopFuture<Void> {
        let topic = Topic(name: topicString)
        return Topic
                .query(on: self.app.db)
                .filter(\.$name == topic.name)
                .first()
                .flatMap { result in
                    if let topic = result {
                        return device.$topics.attach(topic, on: self.app.db)
                    } else {
                        return topic.save(on: self.app.db).flatMap {
                            device.$topics.attach(topic, on: self.app.db)
                        }
                    }
                }
        }
}

enum NotificationCenterEnvironmentKey: EnvironmentKey {
    static var defaultValue = NotificationCenter.shared
}

extension EnvironmentValues {
    /// The environment value to use the `NotificationCenter` in a `Component`.
    public var notificationCenter: NotificationCenter {
        self[NotificationCenterEnvironmentKey.self]
    }
}
// swiftlint:enable first_where
