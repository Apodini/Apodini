// swiftlint:disable first_where
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
public struct NotificationCenter {
    @Throws(.notFound, reason: "Could not find device in database.")
    private var notFoundDevice: ApodiniError
    
    @Throws(.notFound, reason: "Could not find topic in database.")
    private var notFoundTopic: ApodiniError
    
    internal var app: Application
    
    /// Initializes the `NotificationCenter` with an `Application` instance.
    public init(app: Application) {
        self.app = app
    }
    
    // Checks the APNS Configuration.
    internal var isAPNSConfigured: Bool {
        if app.apns.configuration == nil {
            app.logger.error("""
                APNS is not configured correctly.
                Please use the `APNSConfiguration` in the `configuration` property.
            """)
            return false
        }
        return true
    }
    
    // Checks the FCM Configuration.
    internal var isFCMConfigured: Bool {
        if app.fcm.configuration == nil {
            app.logger.error("""
                FCM is not configured correctly.
                Please use the `FCMConfiguration` in the `configuration` property.
            """)
            return false
        }
        return true
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
            .save(on: app.database)
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
            .query(on: app.database)
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
            .query(on: app.database)
            .filter(\.$id == id)
            .with(\.$topics)
            .first()
            .unwrap(or: self.notFoundDevice)
            .map { $0.transform() }
    }
    
    /// Retrieves all `Device`s for `APNS` in the database.
    ///
    /// - Returns: An array of all stored `Device`s with type `apns`.
    public func getAPNSDevices() -> EventLoopFuture<[Device]> {
        DeviceDatabaseModel
            .query(on: app.database)
            .filter(\.$type == .apns)
            .with(\.$topics)
            .all()
            .mapEach { $0.transform() }
    }
    
    /// Retrieves all `APNS` `Device`s subscribed to a topic
    ///
    /// - Returns: An array of all stored `Device`s of type `apns`.
    public func getAPNSDevices(of topic: String) -> EventLoopFuture<[Device]> {
        query(for: topic)
            .map { topic in
                topic.devices.compactMap {
                    if $0.type == .apns {
                        return $0.transform()
                    }
                    return nil
                }
            }
    }
    
    /// Retrieves all `FCM` `Device`s subscribed to a topic
    ///
    /// - Returns: An array of all stored `Device`s of type `fcm`.
    public func getFCMDevices(of topic: String) -> EventLoopFuture<[Device]> {
        query(for: topic)
            .map { topic in
                topic.devices.compactMap {
                    if $0.type == .fcm {
                        return $0.transform()
                    }
                    return nil
                }
            }
    }
    
    /// Retrieves all `Device`s for `FCM` in the database.
    ///
    /// - Returns: An array of all stored `Device`s with type `fcm`.
    public func getFCMDevices() -> EventLoopFuture<[Device]> {
        DeviceDatabaseModel
            .query(on: app.database)
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
        query(for: topic)
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
            .find(device.id, on: app.database)
            .unwrap(or: self.notFoundDevice)
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
            .query(on: app.database)
            .filter(\.$name == topic)
            .first()
            .unwrap(or: self.notFoundTopic)
            .flatMap { topicModel in
                DeviceDatabaseModel
                    .find(device.id, on: self.app.database)
                    .unwrap(or: self.notFoundDevice)
                    .flatMap { deviceDatabaseModel -> EventLoopFuture<Void> in
                        deviceDatabaseModel.$topics.detach(topicModel, on: self.app.database)
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
            .find(device.id, on: app.database)
            .unwrap(or: self.notFoundDevice)
            .flatMap { $0.delete(on: self.app.database) }
    }
}

// MARK: - Private Extension

private extension NotificationCenter {
    func query(for topic: String) -> EventLoopFuture<Topic> {
        Topic
            .query(on: app.database)
            .filter(\.$name == topic)
            .with(\.$devices) { devices in // Pre-loads sibling relations
                devices.with(\.$topics)
            }
            .first()
            .unwrap(or: notFoundTopic)
    }
    
    func attach(topics: [String], to device: DeviceDatabaseModel) -> EventLoopFuture<Void> {
        topics.map {
            attach(topic: $0, to: device)
        }
        .flatten(on: app.database.eventLoop)
    }
    
    func attach(topic topicString: String, to device: DeviceDatabaseModel) -> EventLoopFuture<Void> {
        let topic = Topic(name: topicString)
        return Topic
            .query(on: self.app.database)
            .filter(\.$name == topic.name)
            .first()
            .flatMap { result in
                if let topic = result {
                    return device.$topics.attach(topic, method: .ifNotExists, on: self.app.database)
                } else {
                    return topic.save(on: self.app.database).flatMap {
                        device.$topics.attach(topic, method: .ifNotExists, on: self.app.database)
                    }
                }
            }
    }
}
// swiftlint:enable first_where
