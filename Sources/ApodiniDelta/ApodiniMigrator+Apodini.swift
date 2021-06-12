//
//  File.swift
//  
//
//  Created by Eldi Cano on 12.06.21.
//

import Foundation
import ApodiniMigrator
import Apodini
import Logging

// MARK: - ApodiniMigrator.Parameter
extension ApodiniMigrator.Parameter {
    static func of<H: Handler>(_ handler: H.Type, from: Apodini.AnyEndpointParameter, with logger: Logger) -> ApodiniMigrator.Parameter {
        let hasDefaultValue = from.typeErasuredDefaultValue != nil
        var typeInformation: TypeInformation
        do {
            typeInformation = try TypeInformation(type: from.propertyType)
            if from.nilIsValidValue {
                typeInformation = typeInformation.asOptional
            }
        } catch {
            logger.error(
                """
                Error encountered while building the `TypeInformation` for \(from.propertyType) of parameter \(from.name) in handler \(H.self): \(error).
                Using \(Null.self) for the type of the parameter.
                """
            )
            typeInformation = .scalar(.null)
        }
        
        return .init(
            parameterName: from.name,
            typeInformation: typeInformation,
            hasDefaultValue: hasDefaultValue,
            parameterType: .init(from.parameterType))
    }
}

// MARK: - Array
extension Array where Element == Apodini.AnyEndpointParameter {
    func migratorParameters<H: Handler>(of handler: H.Type, with logger: Logger) -> [ApodiniMigrator.Parameter] {
        map { ApodiniMigrator.Parameter.of(H.self, from: $0, with: logger) }
    }
}

// MARK: - ApodiniMigrator.Operation
extension ApodiniMigrator.Operation {
    init(_ from: Apodini.Operation) {
        switch from {
        case .create: self = .create
        case .read: self = .read
        case .update: self = .update
        case .delete: self = .delete
        }
    }
}

// MARK: - ApodiniMigrator.ParameterType
extension ApodiniMigrator.ParameterType {
    init(_ from: Apodini.ParameterType) {
        switch from {
        case .lightweight: self = .lightweight
        case .content:  self = .content
        case .path: self = .path
        case .header: self = .header
        }
    }
}

// MARK: - ApodiniMigrator.Version
extension ApodiniMigrator.Version {
    init(_ from: Apodini.Version) {
        self.init(
            prefix: from.prefix,
            major: from.major,
            minor: from.minor,
            patch: from.patch
        )
    }
}
