//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Apodini
import FluentKit
@_implementationOnly import Runtime


internal struct QueryBuilder<Model: DatabaseModel> {
    private let type: Model.Type
    internal var parameters: [FieldKey: TypeContainer] = [:]

    init(type: Model.Type, parameters: [FieldKey: TypeContainer]) {
        self.type = type
        self.parameters = parameters
    }
    
    internal func execute(on database: FluentKit.Database) -> EventLoopFuture<[Model]> {
        let queryBuilder = Model.query(on: database)
        for (key, value) in parameters {
            queryBuilder.filter(key: key, method: .equal, codableValue: value)
        }
        return queryBuilder.all()
    }
    
    internal static func info(for type: Model.Type) -> [ModelInfo] {
        var modelInfo: [ModelInfo] = []
        let keys = type.keys
        for (index, child) in Mirror(reflecting: Model()).children.enumerated() {
            let key = keys[index]
            if let idVisitable = child.value as? VisitableIDProperty {
                let concreteCodable = idVisitable.accept(ConcreteIDPropertyVisitor())
                modelInfo.append(ModelInfo(key: key, value: concreteCodable))
            }
            if let fieldVisitable = child.value as? VisitableFieldProperty {
                let concreteCodable = fieldVisitable.accept(ConcreteTypeVisitor())
                modelInfo.append(ModelInfo(key: key, value: concreteCodable))
            }
        }
        return modelInfo
    }
    
    static func parameter<T: Codable>(_: T? = nil) -> Parameter<T?> {
        Parameter<T?>(.http(.query))
    }
}

extension FluentKit.QueryBuilder {
    // swiftlint:disable cyclomatic_complexity
    func filter(key: FieldKey, method: DatabaseQuery.Filter.Method, codableValue: TypeContainer) {
        switch codableValue {
        case .bool(let value):
            self.filter(key, method, value)
        case .string(let value):
            self.filter(key, method, value)
        case .int(let value):
            self.filter(key, method, value)
        case .int8(let value):
            self.filter(key, method, value)
        case .int16(let value):
            self.filter(key, method, value)
        case .int32(let value):
            self.filter(key, method, value)
        case .int64(let value):
            self.filter(key, method, value)
        case .uint(let value):
            self.filter(key, method, value)
        case .uint8(let value):
            self.filter(key, method, value)
        case .uint16(let value):
            self.filter(key, method, value)
        case .uint32(let value):
            self.filter(key, method, value)
        case .uint64(let value):
            self.filter(key, method, value)
        case .uuid(let value):
            self.filter(key, method, value)
        case .float(let value):
            self.filter(key, method, value)
        case .double(let value):
            self.filter(key, method, value)
        case .noValue:
            break
        }
    }
}
