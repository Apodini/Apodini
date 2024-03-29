//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation

/// A property wrapper that can be used on `Handler`s to obtain `ApodiniError`s.
@propertyWrapper
public struct Throws {
    private let options: PropertyOptionSet<ErrorOptionNameSpace>

    private let `type`: ErrorType
    
    private let reason: String?
    
    private let description: String?

    private let information: InformationSet
    
    internal init(
        type: ErrorType,
        reason: String? = nil,
        description: String? = nil,
        information: InformationSet = [],
        _ options: [ApodiniError.Option]
    ) {
        self.options = PropertyOptionSet(options)
        self.type = `type`
        self.reason = reason
        self.description = description
        self.information = information
    }

    /// Create a new `ApodiniError` from its base components:
    /// - Parameter `type`: The associated `ErrorType`. If `other` is chosen, the `options` should be
    ///   used to provide additional guidance for the exporters.
    /// - Parameter `reason`: The **public** reason explaining what led to the this error.
    /// - Parameter `description`: The **internal** description of this error. This will only be exposed in `DEBUG` mode.
    /// - Parameter `options`: Possible exporter-specific options that provide guidance for how to handle this error.
    public init(
        _ type: ErrorType,
        reason: String? = nil,
        description: String? = nil,
        _ options: ApodiniError.Option...
    ) {
        self.init(type: type, reason: reason, description: description, options)
    }
    
    /// Create a new `ApodiniError` from its base components:
    /// - Parameter `type`: The associated `ErrorType`. If `other` is chosen, the `options` should be
    ///   used to provide additional guidance for the exporters.
    /// - Parameter `reason`: The **public** reason explaining what led to the this error.
    /// - Parameter `description`: The **internal** description of this error. This will only be exposed in `DEBUG` mode.
    /// - Parameter `information`: Possible array of `Information` entries attached to the `Response`.
    /// - Parameter `options`: Possible exporter-specific options that provide guidance for how to handle this error.
    public init(
        _ type: ErrorType,
        reason: String? = nil,
        description: String? = nil,
        information: AnyInformation...,
        options: ApodiniError.Option...
    ) {
        self.init(type: type, reason: reason, description: description, information: InformationSet(information), options)
    }
    
    /// An `ApodiniError` which is based on the information passed into this property wrapper. The
    /// `ApodiniError` can be called as a function to modify the errors `reason` and `description`.
    public var wrappedValue: ApodiniError {
        ApodiniError(type: self.type, reason: self.reason, description: self.description, information: information, self.options)
    }
}
