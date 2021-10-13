//
//  ReadAll.swift
//
//
//  Created by Paul Schmiedmayer on 2/24/21.
//

import FluentKit
import Apodini


/// A Handler that returns an array of `DatabaseModel` which all conform to the query parameters of the request.
/// It accepts all parameters that represent properties of the specified `DatabaseModel`.
/// It uses the database that has been specified in the `DatabaseConfiguration`.
/// An Example using a REST request:
/// Group("api", "birds") {
///     Read<Bird>()
/// }
/// Sending a request to  ~/api/birds/birds?age=19&name=Foo would 
/// return an array of `Bird` object that have an age of 19 and the name Foo.
public struct ReadAll<Model: FluentKit.Model & Apodini.Content>: Handler {
    @Apodini.Environment(\.database)
    private var database: FluentKit.Database
    
    @Properties
    private var properties: [String: Apodini.Property]
    
    
    public init() {
        self._properties = Properties(wrappedValue: Model.filterableFieldKeyProperties.dynamics)
    }
    
    
    public func handle() throws -> EventLoopFuture<[Model]> {
        database
            .query(Model.self)
            .filter(basedOn: properties)
            .all()
    }
}
