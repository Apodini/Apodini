//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import FluentKit
import Apodini

/// Creates, if possible, an array of object in the database that conform to `DatabaseModel`
/// See also `Create`.
public struct CreateAll<Model: DatabaseModel>: Handler {
    @Apodini.Environment(\.database)
    private var database: FluentKit.Database
    
    @Environment(\.eventLoopGroup)
    private var eventLoopGroup: EventLoopGroup
    
    @Parameter
    private var objects: [Model]
    
    
    public init() {}
    
    
    public func handle() -> EventLoopFuture<Response<[Model]>> {
        eventLoopGroup.next()
            .flatten(
                objects.compactMap { object in
                    object.save(on: database)
                }
            )
            .map { _ in
                .final(objects, status: .created)
            }
    }
    
    public var metadata: AnyHandlerMetadata {
        Operation(.create)
    }
}
