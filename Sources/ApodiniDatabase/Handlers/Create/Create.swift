//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import FluentKit
import Apodini

/// A Handler that creates, if possible, an object in the database that conforms to `DatabaseModel` out of the body of the request.
/// It uses the database that has been specified in the `DatabaseConfiguration`.
public struct Create<Model: DatabaseModel>: Handler {
    @Apodini.Environment(\.database)
    private var database: FluentKit.Database
    
    @Parameter
    private var object: Model

    public func handle() -> EventLoopFuture<Apodini.Response<Model>> {
        object
            .save(on: database)
            .map { _ in
                .final(object, status: .created)
            }
    }
    
    public init() {}
}
