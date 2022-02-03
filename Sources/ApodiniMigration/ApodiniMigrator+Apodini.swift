//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import ApodiniMigratorCore
import Apodini
@_implementationOnly import Logging

// MARK: - ApodiniMigratorCore.Parameter
extension ApodiniMigratorCore.Parameter {
    static func of<H: Handler>(_ type: H.Type, from parameter: Apodini.AnyEndpointParameter, with logger: Logger) -> ApodiniMigratorCore.Parameter {
        let typeInformation: TypeInformation
        do {
            typeInformation = try TypeInformation(type: parameter.propertyType)
        } catch {
            logger.error(
                """
                Error encountered while building the `TypeInformation` for \(parameter.propertyType) of parameter \(parameter.name) in handler \(H.self): \(error).
                Using \(Data.self) for the type of the parameter.
                """
            )
            typeInformation = .scalar(.data)
        }
        let isRequired: Bool = {
            parameter.parameterType == .path
                || (!parameter.nilIsValidValue
                        && !parameter.hasDefaultValue
                        && parameter.option(for: .optionality) != .optional)
        }()

        return .init(
            name: parameter.name,
            typeInformation: typeInformation,
            parameterType: .init(parameter.parameterType),
            isRequired: isRequired
        )
    }
}

// MARK: - Array
extension Array where Element == Apodini.AnyEndpointParameter {
    func migratorParameters<H: Handler>(of handler: H.Type, with logger: Logger) -> [ApodiniMigratorCore.Parameter] {
        map { .of(H.self, from: $0, with: logger) }
    }
}

// MARK: - ApodiniMigratorCore.Operation
extension ApodiniMigratorCore.Operation {
    init(_ from: Apodini.Operation) {
        switch from {
        case .create: self = .create
        case .read: self = .read
        case .update: self = .update
        case .delete: self = .delete
        }
    }
}

extension ApodiniMigratorCore.CommunicationalPattern {
    init(_ from: Apodini.CommunicationPattern) {
        switch from {
        case .requestResponse:
            self = .requestResponse
        case .serviceSideStream:
            self = .serviceSideStream
        case .clientSideStream:
            self = .clientSideStream
        case .bidirectionalStream:
            self = .bidirectionalStream
        }
    }
}

// MARK: - ApodiniMigratorCore.ParameterType
extension ApodiniMigratorCore.ParameterType {
    init(_ from: Apodini.ParameterType) {
        switch from {
        case .lightweight: self = .lightweight
        case .content:  self = .content
        case .path: self = .path
        }
    }
}

// MARK: - ApodiniMigratorCore.Version
extension ApodiniMigratorCore.Version {
    init(with version: Apodini.Version) {
        self.init(
            prefix: version.prefix,
            major: version.major,
            minor: version.minor,
            patch: version.patch
        )
    }
}
