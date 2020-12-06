//
//  File.swift
//  
//
//  Created by Alexander Collins on 14.11.20.
//

import Fluent
import Vapor

public final class DeviceDatabaseModel: Model {
    public static let schema = "NotificationDevice"

    @ID(custom: "id", generatedBy: .user)
    public var id: String?
    
    @Enum(key: .type)
    public var type: DeviceType
    
    @Field(key: "topics")
    public var topics: [String]
    
    public init() { }
    
    public init(id: String, type: DeviceType, topics: [String] = []) {
        self.id = id
        self.type = type
        self.topics = topics
    }
    
    public func transform() -> Device {
        Device(id: id!, type: type, topics: topics)
    }
}

public struct Device: Content {
    public var id: String
    public var type: DeviceType
    public var topics: [String]?
    
    public init(id: String, type: DeviceType, topics: [String]? = nil) {
        self.id = id
        self.type = type
        self.topics = topics
    }
    
    public func transform() -> DeviceDatabaseModel {
        DeviceDatabaseModel(id: id, type: type, topics: topics ?? [])
    }
}

extension FieldKey {
    static var type: Self { "type" }
}

public enum DeviceType: String, Codable, CaseIterable {
    static var name: FieldKey { .type }
    
    case apns
    case fcm
}

extension DeviceType: Content { }

internal struct DeviceMigration: Migration {
    func prepare(on database: Fluent.Database) -> EventLoopFuture<Void> {
        database.enum("type")
            .case("apns")
            .case("fcm")
            .create()
            .flatMap { enumType in
                database.schema(DeviceDatabaseModel.schema)
                    .field("id", .string, .identifier(auto: false))
                    .field("type", enumType, .required)
                    .field("topics", .array(of: .string), .required)
                    .create()
            }
    
    }
    
    func revert(on database: Fluent.Database) -> EventLoopFuture<Void> {
        database.enum("type").delete().flatMap {
            database.schema(DeviceDatabaseModel.schema).delete()
        }
    }
}

extension Device: Equatable {
    public static func == (lhs: Device, rhs: Device) -> Bool {
        lhs.id == rhs.id
    }
}
