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
        var dynamicValues: [String: Parameter<AnyConcreteCodable?>] = [:]
        let infos = QueryBuilder.info(for: Model.self)
        for info in infos {
            dynamicValues[info.key.description] = QueryBuilder<Model>.parameter(for: info.value)
        }
        _dynamics = Properties(wrappedValue: dynamicValues)
        print(dynamics)
    }

    public func handle() -> String {
//    public func handle() -> [Model] {
//        let queryInfo: [FieldKey: AnyGenericCodable] = _dynamics.typed(Parameter<AnyGenericCodable?>.self)
//            .reduce(into: [FieldKey: String?](), { result, entry in
//                result[Model.fieldKey(for: entry.0)] = entry.1.wrappedValue
//            })
//            .compactMapValues { $0 }
        let queryInfo: [FieldKey: AnyConcreteCodable] = _dynamics.typed(Parameter<AnyConcreteCodable?>.self)
            .reduce(into: [FieldKey: AnyConcreteCodable](), { result, entry in
                result[Model.fieldKey(for: entry.0)] = entry.1.wrappedValue
        }).compactMapValues({ $0 })
            .filter({ (key, value) in value.wrappedType != .noValue })
        print("info after decoding")
        print(queryInfo)
        let queryBuilder = QueryBuilder(type: Model.self, parameters: queryInfo)
        queryBuilder.execute(on: database)
        return queryInfo.debugDescription
    }
}
