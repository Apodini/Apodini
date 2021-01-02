import Foundation
import Fluent

public struct Read<Model: DatabaseModel>: Handler where Model.IDValue: LosslessStringConvertible {
    
    @Apodini.Environment(\.database)
    var database: Fluent.Database
    
    @Parameter var dummy: String

    @Properties var dynamics: [String: Apodini.Property]
    
    
    public init(_ dummy: Parameter<String>) {
        self._dummy = dummy
        var dynamicValues: [String: Parameter<String?>] = [:]
        let infos = QueryBuilder.info(for: Model.self)
        for info in infos {
            dynamicValues[info.key.description] = Parameter<String?>(.database(info))
        }
        _dynamics = Properties(wrappedValue: dynamicValues)
    }

//    public func handle() -> EventLoopFuture<[Model]> {
    public func handle() -> String {
        let queryInfo: [FieldKey: String] = _dynamics.typed(Parameter<String?>.self)
            .reduce(into: [FieldKey: String?](), { result, entry in
                result[Model.fieldKey(for: entry.0)] = entry.1.wrappedValue
            })
            .compactMapValues({ $0 })
        let queryBuilder = Apodini.QueryBuilder(type: Model.self, parameters: queryInfo)
        queryBuilder.execute(on: database)
        return queryInfo.debugDescription
    }
}
