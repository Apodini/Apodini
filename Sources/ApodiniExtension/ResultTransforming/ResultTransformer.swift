//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import Apodini
import ApodiniUtils
import NIO

// MARK: ResultTransformer

/// A ``ResultTransformer`` provides a strategies for handling both
/// cases of a `Result`.
public protocol ResultTransformer {
    /// The type carried by `Result`'s `success(_:)` case
    associatedtype Input
    /// The type ``ResultTransformer/Input`` is transformed to
    associatedtype Output
    /// The error type emits when escalating an error contained in the
    /// `Result`'s `failure(_:)` case
    associatedtype Failure: Error
    
    /// Defines a strategy that shall be used to resolve or escalate the given `error`.
    func handle(error: ApodiniError) -> ErrorHandlingStrategy<Output, Failure>
    
    /// Transforms the `input` to an instance of type ``ResultTransformer/Output`` or throws.
    ///
    /// - Note: If ``transform(input:)`` throws an error, it shall be given the chance to
    /// resolve this error with a call to ``handle(error:)``.
    func transform(input: Input) throws -> Output
}

/// A strategy for dealing with `Error`s.
public enum ErrorHandlingStrategy<Output, Failure: Error> {
    /// The error could be recovered by providing an alternative representation
    case graceful(Output)
    /// The error is not of importance and the result can be discarded
    case ignore
    /// The error must be escalated
    case abort(Failure)
    /// The error could be recovered by providing an alternative representation, but
    /// the associated process must be completed nevertheless
    case complete(Output)
}
