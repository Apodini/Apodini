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
        database.enum("type")
            .case("apns")
            .case("fcm")
            .create()
            .flatMap { enumType in
                database.schema(DeviceDatabaseModel.schema)
                    .field("id", .string, .identifier(auto: false))
                    .field("type", enumType, .required)
                    .field("topics", .array(of: .string))
                    .create()
            }
        
    }
    
    func revert(on database: Fluent.Database) -> EventLoopFuture<Void> {
        database.enum("type").delete().flatMap {
            database.schema(DeviceDatabaseModel.schema).delete()
        }
    }
}

