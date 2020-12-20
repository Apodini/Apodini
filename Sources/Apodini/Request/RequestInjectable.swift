//
//  Request.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//
import NIO
import Vapor
@_implementationOnly import Runtime
import Fluent

protocol RequestInjectable {
    mutating func inject(using request: Vapor.Request, with decoder: RequestInjectableDecoder?) throws
    func accept(_ visitor: RequestInjectableVisitor)
}

extension RequestInjectable {
    func accept(_ visitor: RequestInjectableVisitor) {
        visitor.visit(self)
    }
}

protocol RequestInjectableDecoder {
    func decode<T: Decodable>(_ type: T.Type, from request: Vapor.Request) throws -> T?
}

protocol RequestInjectableVisitor {
    func visit<Injectable: RequestInjectable>(_ requestInjectable: Injectable)

    func visit<Element>(_ parameter: Parameter<Element>)
}
extension RequestInjectableVisitor {
    func visit<Injectable: RequestInjectable>(_ requestInjectable: Injectable) {}
    func visit<Element>(_ parameter: Parameter<Element>) {}
}


private func extractRequestInjectables<Element>(from subject: Element) -> [String: RequestInjectable] {
    var result: [String: RequestInjectable] = [:]
    
    execute({ (injectable: RequestInjectable, label: String) in
        result[label] = injectable
    }, on: subject)
    
    return result
}

extension Component {
    func extractRequestInjectables() -> [String: RequestInjectable] {
        Apodini.extractRequestInjectables(from: self)
    }
}
extension AnyResponseTransformer {
    func extractRequestInjectables() -> [String: RequestInjectable] {
        Apodini.extractRequestInjectables(from: self)
    }
}

extension Vapor.Request {
    func enterRequestContext<E, R>(with element: E, using decoder: RequestInjectableDecoder? = nil, executing method: (E) -> EventLoopFuture<R>)
                    -> EventLoopFuture<R> {
        var element = element
        inject(in: &element, using: decoder)

        return method(element)
    }

    func enterRequestContext<E, R>(with element: E, using decoder: RequestInjectableDecoder? = nil, executing method: (E) -> R) -> R {
        var element = element
        inject(in: &element, using: decoder)
        return method(element)
    }
    
    private func inject<E>(in element: inout E, using decoder: RequestInjectableDecoder? = nil) {
        // Inject all properties that can be injected using RequestInjectable
        let elem = element
        
        apply({ (requestInjectable: inout RequestInjectable) in
            do {
                try requestInjectable.inject(using: self, with: decoder)
            } catch {
                fatalError("Injecting into element \(elem) failed.")
            }
        }, to: &element)
    }
}


protocol FieldKeyMap: DynamicProperty {
    associatedtype Model: DatabaseModel
    func filter(query: Fluent.QueryBuilder<Model>) -> Fluent.QueryBuilder<Model>
    
    var fieldKey: FieldKey { get }
}

struct ConcreteFieldKeyMap<T, Model>: FieldKeyMap where T: Codable, Model: DatabaseModel {

    var fieldKey: FieldKey
    
    let method: DatabaseQuery.Filter.Method = .equal
    
    @Parameter("", .http(.query))
    var parameter: T?
    
//    init(fieldKey: FieldKey, method: DatabaseQuery.Filter.Method = .equal, parameter: Parameter<T>) {
//        self.fieldKey = fieldKey
//        self.method = method
//        self.parameter = parameter
//    }
    
    func filter(query: Fluent.QueryBuilder<Model>) -> Fluent.QueryBuilder<Model> {
        guard let value = parameter else { return query }
        return query.filter(fieldKey, method, value)
    }
}

@propertyWrapper
struct Injectables<Property: FieldKeyMap>: RequestInjectable {
    var injectables: [String: Property]?
    
    var wrappedValue: [String: Property] {
        guard let injectables = injectables else {
            fatalError("You can only access the body while you handle a request")
        }
        
        return injectables
    }
    
    func inject(using request: Request, with decoder: RequestInjectableDecoder?) throws {
        guard let injectables = injectables else { fatalError("injectables is nil.") }
        
    }
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
        print(QueryBuilder.info(for: Model.self))
        var dynamicValues: [String: Param] = [:]
        let infos = QueryBuilder.info(for: Model.self)
        for info in infos {
            dynamicValues[info.key.description] = Param(String(info.key.description))
        }
        
        _dynamics = Dynamics(wrappedValue: dynamicValues)
    }

    public func handle() -> EventLoopFuture<[Model]> {
        var result = ""
        for (key, value) in dynamics {
            result.append("\(key) - \(value.wrappedValue ?? "nil")\n")
        }
        let queryInfo: [FieldKey: String] = dynamics
            .reduce(into: [FieldKey: String?](), { result, entry in
                result[Model.fieldKey(for: entry.key)] = entry.value.wrappedValue
            })
            .compactMapValues({ $0 })
        let queryBuilder = Apodini.QueryBuilder(type: Model.self, parameters: queryInfo)
        return queryBuilder.execute(on: database)
    }
}

@propertyWrapper
struct Param: RequestInjectable {
    mutating func inject(using request: Request, with decoder: RequestInjectableDecoder?) throws {
        print("nice")
    }
    
    var _value: String?
    
    var wrappedValue: String? {
        _value
    }
    
    init(_ value: String?) {
        if value == "id" || value == "name" {
            self._value = nil
        } else if value == "age" {
            self._value = "19"
        }
    }
}

//injectables = Model.keys.map( { key in
//    let parameter = Parameter(key.description, .http(.query))
//    ConcreteFieldKeyMap(fieldKey: key, parameter: parameter)
//})
