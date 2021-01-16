import Foundation
import Fluent
import Apodini

/// A Handler that returns an array of `DatabaseModel` which all conform to the query parameters of the request.
/// It accepts all parameters that represent properties of the specified `DatabaseModel`.
/// It uses the database that has been specified in the `DatabaseConfiguration`.
/// An Example using a REST request:
/// Group("api", "birds") {
///     Read<Bird>()
/// }
/// Sending a request to  ~/api/birds/birds?age=19&name=Foo would 
///return an array of `Bird` object that have an age of 19 and the name Foo.
public struct Read<Model: DatabaseModel>: Handler {
    @Apodini.Environment(\.database)
    private var database: Fluent.Database

    @Properties
    private var dynamics: [String: Apodini.Property]
    
    public init() {
        var dynamicValues: [String: Parameter<TypeContainer?>] = [:]
        let infos = QueryBuilder.info(for: Model.self)
        for info in infos {
            dynamicValues[info.key.description] = QueryBuilder<Model>.parameter(for: info.value)
        }
        _dynamics = Properties(wrappedValue: dynamicValues)
    }

    public func handle() -> EventLoopFuture<[Model]> {
        let queryInfo: [FieldKey: TypeContainer] = _dynamics.typed(Parameter<TypeContainer?>.self)
            .reduce(into: [FieldKey: TypeContainer](), { result, entry in
                result[Model.fieldKey(for: entry.0)] = entry.1.wrappedValue
        }).compactMapValues({ $0 })
            .filter({ (key, value) in value != .noValue })
        let queryBuilder = QueryBuilder(type: Model.self, parameters: queryInfo)
        return queryBuilder.execute(on: database)
    }
}
