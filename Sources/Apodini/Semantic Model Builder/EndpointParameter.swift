//
//  EndpointParameter.swift
//  
//
//  Created by Lorena Schlesinger on 06.12.20.
//

import Runtime
import Foundation

struct EndpointParameter {
    let id: UUID
    let name: String?
    let label: String
    let contentType: Any.Type
    let options: PropertyOptionSet<ParameterOptionNameSpace>
    let parameterType: EndpointParameterType
    
    /// `@Parameter` categorization needed for certain interface exporters (e.g., HTTP-based).
    enum EndpointParameterType {
        case lightweight
        case content
        case path
    }

    static func create(from requestInjectables: [String: RequestInjectable]) -> [EndpointParameter] {
        requestInjectables
            .compactMap {
                create(from: $0.value, label: $0.key)
            }
    }
    
    static func create(from pathComponent: _PathComponent, label: String) -> EndpointParameter? {
        guard let info: TypeInfo = try? typeInfo(of: type(of: pathComponent)) else {
            return nil
        }
        return create(from: info, source: pathComponent, label: label)
    }
    
    static func create(from requestInjectable: RequestInjectable, label: String) -> EndpointParameter? {
        guard let info: TypeInfo = try? typeInfo(of: type(of: requestInjectable)) else {
            return nil
        }
        return create(from: info, source: requestInjectable, label: label)
    }
    
    /// TODO: Why does this not work with `create<T>(from source: T, ...) { typeInfo(of: type(of: source)) ... }`
    private static func create<T>(from info: TypeInfo, source: T, label: String) -> EndpointParameter? {
        /// Parameter<String> serves as representative `parameterType` of any Parameter<T> as  `mangeldName` of all Parameter<T> is `Parameter`
        let parameterType = try? typeInfo(of: Parameter<String>.self)
        if info.mangledName == parameterType?.mangledName {
            let mirror = Mirror(reflecting: source)
            // swiftlint:disable:next force_cast
            let id = mirror.children.first { $0.label == ParameterProperties.id }!.value as! UUID
            let name = mirror.children.first { $0.label == ParameterProperties.name }?.value as? String
            let contentType = info.genericTypes[0]
            // swiftlint:disable:next force_cast
            let options = mirror.children.first { $0.label == ParameterProperties.options }!.value as! PropertyOptionSet<ParameterOptionNameSpace>
            
            let parameterType: EndpointParameter.EndpointParameterType = {
                var result: EndpointParameter.EndpointParameterType = .lightweight
                let isLosslessStringConvertible = contentType is LosslessStringConvertible.Type
                let option = options.option(for: PropertyOptionKey.http)
                switch option {
                case .path:
                    precondition(isLosslessStringConvertible, "Invalid explicit option .path for parameter \(name ?? label). Option is only available for wrapped properties conforming to \(LosslessStringConvertible.self).")
                    result = .path
                case .query:
                    precondition(isLosslessStringConvertible, "Invalid explicit option .query for parameter \(name ?? label). Option is only available for wrapped properties conforming to \(LosslessStringConvertible.self).")
                    result = .lightweight
                case .body:
                    result = .content
                default:
                    if !isLosslessStringConvertible {
                        result = .content
                    }
                }
                return result
            }()
            
            return EndpointParameter(
                id: id,
                name: name,
                label: label,
                contentType: contentType,
                options: options,
                parameterType: parameterType)
        }
        return nil
    }
}

extension EndpointParameter: Equatable, Hashable {
    static func == (lhs: EndpointParameter, rhs: EndpointParameter) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
