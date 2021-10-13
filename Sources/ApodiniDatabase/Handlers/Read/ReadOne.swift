//
//  ReadOne.swift
//
//
//  Created by Paul Schmiedmayer on 2/24/21.
//

import FluentKit
import Apodini


public struct ReadOne<Model: FluentKit.Model & Apodini.Content>: Handler {
    @Apodini.Environment(\.database)
    private var database: FluentKit.Database
    
    @Parameter(.http(.path))
    var id: Model.IDValue
    
    @Throws(.notFound, reason: "No object was found in the database under the given id")
    var objectNotFoundError: ApodiniError
    
    
    public init() {}
    
    
    public func handle() throws -> EventLoopFuture<Model> {
        Model.find(id, on: database)
            .unwrap(orError: objectNotFoundError)
    }
}
