//
//  CreateAll.swift
//
//
//  Created by Paul Schmiedmayer on 2/24/21.
//

import FluentKit
import Apodini


/// Creates, if possible, an array of object in the database that conform to `DatabaseModel`
/// See also `Create`.
public struct CreateAll<Model: FluentKit.Model & Apodini.Content>: Handler {
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
}
