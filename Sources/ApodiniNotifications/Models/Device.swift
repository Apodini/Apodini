//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import FluentKit
import Apodini

public final class DeviceDatabaseModel: Model, Content {
    public static let schema = "notification_device"
    
    @ID(custom: "id", generatedBy: .user)
    public var id: String?
    
    @Enum(key: .type)
    public var type: DeviceType
    
    @Siblings(through: DeviceTopic.self, from: \.$device, to: \.$topic)
    public var topics: [Topic]
    
    
    public init() {
        // Empty intializer used by FluentKit
    }
    
    public init(id: String, type: DeviceType) {
        self.id = id
        self.type = type
    }
    
    public func transform() -> Device {
        guard let id = id else {
            fatalError("Could not retrieve id of device")
        }
        let names = topics.map { $0.name }
        return Device(id: id, type: type, topics: names)
    }
}

public final class DeviceTopic: Model, Content {
    public static let schema = "device_topic"
    
    @ID(key: .id)
    public var id: UUID?
    
    @Parent(key: .deviceId)
    public var device: DeviceDatabaseModel
    
    @Parent(key: .topicId)
    public var topic: Topic
    
    public init() {
        // Empty intializer used by FluentKit
    }
    
    init(id: UUID? = nil, device: DeviceDatabaseModel, topic: Topic) throws {
        self.id = id
        self.$device.id = try device.requireID()
        self.$topic.id = try topic.requireID()
    }
}

public final class Topic: Model, Content {
    public static let schema = "topic"
    
    @ID(key: .id)
    public var id: UUID?
    
    @Field(key: .name)
    public var name: String
    
    @Siblings(through: DeviceTopic.self, from: \.$topic, to: \.$device)
    public var devices: [DeviceDatabaseModel]
    
    public init() {
        // Empty intializer used by FluentKit
    }
    
    public init(name: String) {
        self.name = name
    }
}

// swiftlint:disable discouraged_optional_collection
/// A struct used by the `NotificationCenter` to send push notifications.
public struct Device: Codable, Content {
    /// The id used by a push notification service.
    public var id: String
    /// The push notification service to use when sending a message.
    public var type: DeviceType
    /// Topics are used to group multiple `Device`s together to receive the same push notification.
    public var topics: [String]?
    
    public init(id: String, type: DeviceType, topics: [String]? = []) {
        self.id = id
        self.type = type
        self.topics = topics
    }
    
    public func transform() -> DeviceDatabaseModel {
        DeviceDatabaseModel(id: id, type: type)
    }
}
// swiftlint:enable discouraged_optional_collection

extension FieldKey {
    internal static var type: Self { "type" }
    internal static var name: Self { "name" }
    internal static var deviceId: Self { "device_id" }
    internal static var topicId: Self { "topic_id" }
}

public enum DeviceType: String, Codable, CaseIterable {
    static var name: FieldKey { .type }
    
    case apns
}

internal struct DeviceMigration: Migration {
    func prepare(on database: FluentKit.Database) -> EventLoopFuture<Void> {
        database.eventLoop.flatten([
            database.schema(Topic.schema)
                .id()
                .field(.name, .string, .required)
                .unique(on: .name)
                .create(),
            database.enum("type")
                .case("apns")
                .create()
                .flatMap { enumType in
                    database.schema(DeviceDatabaseModel.schema)
                        .field(.id, .string, .identifier(auto: false))
                        .field("type", enumType, .required)
                        .create()
                },
            database.schema(DeviceTopic.schema)
                .id()
                .field(.deviceId, .string, .required)
                .field(.topicId, .uuid, .required)
                .unique(on: .deviceId, .topicId)
                .create()
        ])
    }
    
    func revert(on database: FluentKit.Database) -> EventLoopFuture<Void> {
        database.eventLoop.flatten([
            database.schema(Topic.schema).delete(),
            database.enum("type").delete().flatMap {
                database.schema(DeviceDatabaseModel.schema).delete()
            },
            database.schema(DeviceTopic.schema).delete()
        ])
    }
}

extension Device: Equatable {
    public static func == (lhs: Device, rhs: Device) -> Bool {
        lhs.id == rhs.id
    }
}

extension DeviceDatabaseModel: Equatable {
    public static func == (lhs: DeviceDatabaseModel, rhs: DeviceDatabaseModel) -> Bool {
        lhs.id == rhs.id
    }
}

extension Topic: Equatable {
    public static func == (lhs: Topic, rhs: Topic) -> Bool {
        lhs.name == rhs.name
    }
}
