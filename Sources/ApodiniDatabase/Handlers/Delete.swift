//
//  Delete.swift
//
//
//  Created by Paul Schmiedmayer on 2/24/21.
//

import FluentKit
import Apodini


/// A `Handler` that deletes the object with the given `IDValue` in the database, if it exists. If not an error is thrown.
/// It uses the database that has been specified in the `DatabaseConfiguration`.
public struct Delete<Model: FluentKit.Model>: Handler {
    @Apodini.Environment(\.database)
    private var database: FluentKit.Database

    @Parameter(.http(.path))
    var id: Model.IDValue
    
    @Throws(.notFound, reason: "No object was found in the database under the given id")
    var modelNotFoundError: ApodiniError
    
    
    public init() {}
    
    public func handle() -> EventLoopFuture<Status> {
        Model.find(id, on: database)
            .unwrap(orError: modelNotFoundError)
            .flatMap { $0.delete(on: database ) }
            .transform(to: .noContent)
    }
}
