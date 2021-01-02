//
//  File.swift
//  
//
//  Created by Alexander Collins on 03.12.20.
//

import Fluent
import Apodini

struct DeviceMigration: Migration {
    func prepare(on database: Fluent.Database) -> EventLoopFuture<Void> {
        database.eventLoop.flatten([
            database.schema(Topic.schema)
                .id()
                .field(.name, .string, .required)
                .create(),
            database.enum("type")
                .case("apns")
                .case("fcm")
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
                .create()
        ])
    }
    
    func revert(on database: Fluent.Database) -> EventLoopFuture<Void> {
        database.eventLoop.flatten([
            database.schema(Topic.schema).delete(),
            database.enum("type").delete().flatMap {
                database.schema(DeviceDatabaseModel.schema).delete()
            },
            database.schema(DeviceTopic.schema).delete()
        ])
    }
}

extension FieldKey {
    internal static var type: Self { "type" }
    internal static var name: Self { "name" }
    internal static var deviceId: Self { "device_id" }
    internal static var topicId: Self { "topic_id" }
}
