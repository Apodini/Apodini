//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

@testable import Apodini
@testable import ApodiniDatabase
import Foundation

final class Bird: DatabaseModel {
    static var schema: String = "Birds"
    
    @ID
    var id: UUID?
    @Field(key: "name")
    var name: String
    @Field(key: "age")
    var age: Int
    
    
    init(name: String, age: Int) {
        self.id = nil
        self.name = name
        self.age = age
    }
    
    init() {}
    
    func update(_ object: Bird) {
        if object.id != nil {
            self.id = object.id
        }
        self.age = object.age
        self.name = object.name
    }
}


struct CreateBird: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Bird.schema)
            .id()
            .field("name", .string, .required)
            .field("age", .int, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Bird.schema).delete()
    }
}

extension Bird: Equatable {
    static func == (lhs: Bird, rhs: Bird) -> Bool {
        var result = lhs.name == rhs.name && lhs.age == rhs.age
        
        if let lhsId = lhs.id, let rhsId = rhs.id {
            result = result && lhsId == rhsId
        }
        
        return result
    }
}
