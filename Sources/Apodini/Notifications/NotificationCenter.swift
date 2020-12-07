//
//  NotificationCenter.swift
//  
//
//  Created by Alexander Collins on 12.11.20.
//

import Vapor
import Fluent
import APNS
import FCM

public class NotificationCenter {
    internal static let shared = NotificationCenter()
    internal var application: Application?
    
    private var app: Application {
        guard let app = application else {
            fatalError("The `NotificationCenter` is not configured. Please add the missing configuration to the web service.")
        }
        return app
    }
    
    public var apns: Application.APNS {
        app.apns
    }
    
    public var fcm: FCM {
        app.fcm
    }
    
    init() { }
    
    public func register(device: Device) -> EventLoopFuture<Void> {
        device
            .transform()
            .save(on: app.db)
            .flatMapError { _ in
                self.app.logger.error("Could not save device with id: \(device.id) to databse. It may already be stored in the database.")
                return self.app.eventLoopGroup.future(())
            }
    }
    
    public func getAllDevices() -> EventLoopFuture<[Device]> {
        DeviceDatabaseModel
            .query(on: app.db)
            .all()
            .mapEach { $0.transform() }
    }
    
    public func getAPNSDevices() -> EventLoopFuture<[Device]> {
        DeviceDatabaseModel
            .query(on: app.db)
            .filter(\.$type == .apns)
            .all()
            .mapEach { $0.transform() }
    }
    
    public func getFCMDevices() -> EventLoopFuture<[Device]> {
        DeviceDatabaseModel
            .query(on: app.db)
            .filter(\.$type == .fcm)
            .all()
            .mapEach { $0.transform() }
    }
    
    public func getDevices(of topic: String) -> EventLoopFuture<[Device]> {
        DeviceDatabaseModel
            .query(on: app.db)
            .all()
            .mapEachCompact { device in
                device.topics.contains(topic) ? device.transform() : nil
            }
    }
    
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
    
    @discardableResult
    public func delete(device: Device) -> EventLoopFuture<Void> {
        DeviceDatabaseModel
            .find(device.id, on: app.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.delete(on: self.app.db) }
    }
    
    
    @discardableResult
    public func send(notification: Notification, to device: Device) -> EventLoopFuture<Void> {
        if device.type == .apns {
            return sendAPNS(notification.transformToAPNS(), to: device.id)
        } else {
            return sendFCM(notification.transformToFCM(), to: device.id)
        }
    }
    
    @discardableResult
    public func send<T: Encodable>(notification: Notification, with data: T, to device: Device) -> EventLoopFuture<Void> {
        if device.type == .apns {
            return sendAPNS(notification.transformToAPNS(with: data), to: device.id)
        } else {
            return sendFCM(notification.transformToFCM(with: data), to: device.id)
        }
    }
    
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
    
    @discardableResult
    public func send(notification: Notification, to topic: String) -> EventLoopFuture<[Void]> {
        let fcmNotification = notification.transformToFCM()
        let apnsNotification = notification.transformToAPNS()
        
        return getDevices(of: topic)
            .flatMapEach(on: app.eventLoopGroup.next()) { device in
                device.type == .apns ? self.sendAPNS(apnsNotification, to: device.id) : self.sendFCM(fcmNotification, topic: topic)
            }
    }
    
    @discardableResult
    public func send<T: Encodable>(notification: Notification, with data: T, to topic: String) -> EventLoopFuture<[Void]> {
        let fcmNotification = notification.transformToFCM(with: data)
        let apnsNotification = notification.transformToAPNS(with: data)
        
        return getDevices(of: topic)
            .flatMapEach(on: app.eventLoopGroup.next()) { device in
                device.type == .apns ? self.sendAPNS(apnsNotification, to: device.id) : self.sendFCM(fcmNotification, topic: topic)
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
    public var notificationCenter: NotificationCenter {
        get { self[NotificationCenterEnvironmentKey.self] }
        set { self[NotificationCenterEnvironmentKey.self] = newValue }
    }
}
