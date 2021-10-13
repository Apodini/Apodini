//
//  Update.swift
//
//
//  Created by Paul Schmiedmayer on 2/24/21.
//

import FluentKit
import Apodini


/// A Handler that updates a `DatabaseModel` with the given id with the new object or single parameters of the request.
/// If the request contains a encoded model, `Update` uses this to replace the model found under the given `ID` in the database.
/// If the request contains a set of parameters, `Update` uses these to update their counterparts
/// in the model found under the given `ID` in the database.
/// It uses the database that has been specified in the `DatabaseConfiguration`.
public struct Update<Model: FluentKit.Model & Apodini.Content>: Handler {
    @Apodini.Environment(\.database)
    private var database: FluentKit.Database
    
    @Properties
    private var properties: [String: Apodini.Property]
    
    @Parameter(.http(.path))
    var id: Model.IDValue
    
    @Throws(.notFound, reason: "No object was found in the database under the given id")
    var modelNotFoundError: ApodiniError
    
    
    public init() {
        self._properties = Properties(wrappedValue: Model.updatableFieldKeyProperties.dynamics)
    }
    
    
    public func handle() -> EventLoopFuture<Model> {
        Model
            .find(id, on: database)
            .unwrap(orError: modelNotFoundError)
            .flatMap { model in
                model.updateFields(withProperties: properties)
                return model.update(on: database).transform(to: model)
            }
    }
}
