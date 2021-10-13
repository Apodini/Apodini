//
//  Create.swift
//
//
//  Created by Paul Schmiedmayer on 2/24/21.
//

import FluentKit
import Apodini


/// A Handler that creates, if possible, an object in the database that conforms to `DatabaseModel` out of the body of the request.
/// It uses the database that has been specified in the `DatabaseConfiguration`.
public struct Create<Model: FluentKit.Model & Apodini.Content>: Handler {
    @Apodini.Environment(\.database)
    private var database: FluentKit.Database
    
    @Parameter
    private var object: Model
    
    
    public init() {}
    
    
    public func handle() -> EventLoopFuture<Apodini.Response<Model>> {
        object
            .save(on: database)
            .map { _ in
                .final(object, status: .created)
            }
    }
}
