//
//  File.swift
//  
//
//  Created by Felix Desiderato on 27.11.20.
//

import Foundation
import Fluent
import Vapor

public protocol DatabaseInjectionContext {
    var key: FieldKey { get }
    var type: Any.Type { get }
}

public struct Create<T: DatabaseModel>: Component where T.IDValue == UUID {
    
    @_Request
    var request: Vapor.Request
    
    @_Database
    var database: Fluent.Database
    
    @Parameter
    var object: T

    public func handle() -> EventLoopFuture<T> {
        return object.save(on: database).map({ _ in
            self.object
        })
    }
    
    public init() {}
}

public struct Get<Model: DatabaseModel>: Component where Model.IDValue: LosslessStringConvertible {
//public struct Get<T, Model>: Component where T: Codable, Model: DatabaseModel, Model.IDValue: LosslessStringConvertible {
    
    @_Database
    var database: Fluent.Database
    
    @_Request
    var request: Vapor.Request
    
    @Parameter var dummy: String

    @Dynamics var dynamics: [String: Param]
    
    public init(_ dummy: Parameter<String>) {
        self._dummy = dummy
        var dynamicValues: [String: Param] = [:]
        let infos = QueryBuilder.info(for: Model.self)
        for info in infos {
            dynamicValues[info.key.description] = Param(context: info)
        }
        _dynamics = Dynamics(wrappedValue: dynamicValues)
    }

    public func handle() -> EventLoopFuture<[Model]> {
//        var result = ""
//        for (key, value) in dynamics {
//            result.append("\(key) - \(value.wrappedValue ?? "nil")\n")
//        }
        let queryInfo: [FieldKey: String] = dynamics
            .reduce(into: [FieldKey: String?](), { result, entry in
                result[Model.fieldKey(for: entry.key)] = entry.value.wrappedValue
            })
            .compactMapValues({ $0 })
        let queryBuilder = Apodini.QueryBuilder(type: Model.self, parameters: queryInfo)
        return queryBuilder.execute(on: database)
    }
}

public struct Update<T: DatabaseModel>: Component where T.IDValue: LosslessStringConvertible {
    
    @_Database
    var database: Fluent.Database
    
    @Parameter var object: T
    
    @Parameter var id: T.IDValue
    
    public func handle() -> EventLoopFuture<T> {
        return T.find(id, on: database).flatMapThrowing({ model -> T in
            model?.update(object)
            return model!
        }).flatMap({ model in
            model.update(on: database).map({ model })
        })
    }
}

public struct Delete<T: DatabaseModel>: Component {
    
    @_Database
    var database: Fluent.Database
    
    @_Request
    var request: Vapor.Request
    
    @Apodini.Body
    var object: T
    
    public func handle() -> String {
        let string = String(format: """
        HTTP/DELETE
        Request called on: %@
        DatabaseModel used: %@
        """, request.url.string, object.description)
        return string
    }
    
    public init() {}
}

@propertyWrapper
struct Param: RequestInjectable {
    
    private var context: DatabaseInjectionContext

    var _value: String?
    
    var wrappedValue: String? {
        if context.key == FieldKey("id") || context.key == FieldKey("name") {
            return nil
        }
        return _value
    }
    
    init(_ value: String? = nil, context: DatabaseInjectionContext) {
        self.context = context
        self._value = context.key.description
    }
    
    mutating func inject(using request: Request, with decoder: RequestInjectableDecoder?) throws {
        if let decoder = decoder {
            let test = try decoder.decode(String.self, with: context, from: request)
            _value = test
        }
    }
}

