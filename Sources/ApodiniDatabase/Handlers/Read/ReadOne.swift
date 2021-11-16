//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Apodini
import FluentKit

public struct ReadOne<Model: DatabaseModel>: Handler {
    @Throws(.notFound, reason: "No object was found in the database under the given id")
    var objectNotFoundError: ApodiniError
    
    @Apodini.Environment(\.database)
    private var database: FluentKit.Database
    
    @Parameter(.http(.path))
    var id: Model.IDValue
    
    public func handle() throws -> EventLoopFuture<Model> {
        Model.find(id, on: database).unwrap(orError: objectNotFoundError)
    }
    
    public init() {}
}
