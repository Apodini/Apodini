//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Fluent
import Apodini
@_implementationOnly import Vapor

/// A `Handler` that deletes the object with the given `IDValue` in the database, if it exists. If not an error is thrown.
/// It uses the database that has been specified in the `DatabaseConfiguration`.
public struct Delete<Model: DatabaseModel>: Handler {
    @Apodini.Environment(\.database)
    private var database: Fluent.Database

    @Parameter(.http(.path))
    var id: Model.IDValue
    
    public func handle() -> EventLoopFuture<Status> {
        Model.find(id, on: database)
            .unwrap(orError: Abort(.notFound) )
            .flatMap { $0.delete(on: database ) }
            .transform(to: .noContent)
    }
    
    public init() {}
}
