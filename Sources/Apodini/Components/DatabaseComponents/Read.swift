import Foundation
import Fluent

public struct Read<Model: DatabaseModel>: Component where Model.IDValue: LosslessStringConvertible {
    
    @_Database
    var database: Fluent.Database
    
    @Parameter var dummy: String

    @Dynamics var dynamics: [String: Parameter<String>]
    
    
    public init(_ dummy: Parameter<String>) {
        self._dummy = dummy
        var dynamicValues: [String: Parameter<String>] = [:]
        let infos = QueryBuilder.info(for: Model.self)
        for info in infos {
            dynamicValues[info.key.description] = Parameter<String>(.database(info))
        }
        _dynamics = Dynamics(wrappedValue: dynamicValues)
    }

    public func handle() -> EventLoopFuture<[Model]> {
        let queryInfo: [FieldKey: String] = dynamics
            .reduce(into: [FieldKey: String?](), { result, entry in
                result[Model.fieldKey(for: entry.key)] = entry.value.wrappedValue
            })
            .compactMapValues({ $0 })
        let queryBuilder = Apodini.QueryBuilder(type: Model.self, parameters: queryInfo)
        return queryBuilder.execute(on: database)
    }
}
