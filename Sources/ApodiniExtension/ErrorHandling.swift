//
//  ErrorHandling.swift
//  
//
//  Created by Max Obermeier on 25.06.21.
//

import Foundation
import Apodini
import ApodiniUtils
import OpenCombine
import NIO

// MARK: ResultTransformer

/// A ``ResultTransformer`` provides a strategies for handling both
/// cases of an `Result`.
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


// MARK: Asynchronous Error Handling

extension CancellablePublisher {
    /// A `Publisher` that transforms each incoming `Result` using the given `transformer`
    /// after unwrapping the `Response` for `successful(_:)` input values.
    ///
    /// If a `Response` has no `content` no value is published. If the `Response`'s
    /// `connectionEffect` is `close`, the upstream pipeline is cancelled using
    /// ``CancellablePublisher/cancel()``.
    ///
    /// If the `transformer`'s ``ResultTransformer/handle(error:)`` returns
    /// ``ErrorHandlingStrategy/ignore``, no value is published. In case of
    /// ``ErrorHandlingStrategy/graceful(_:)`` the recovered value is published just
    /// as for `successful(_:)` input values. For ``ErrorHandlingStrategy/complete(_:)``
    /// the value is followed by a `.finished` completion. ``ErrorHandlingStrategy/abort(_:)``
    /// causes a completion with `.failure(_:)`.
    public func transform<T: ResultTransformer>(using transformer: T)
        -> OpenCombine.Publishers.TryCompactMap<Self, T.Output> where Result<Response<T.Input>, Error> == Output {
        self.tryCompactMap { result -> T.Output? in
            switch result {
            case let .success(response):
                if response.connectionEffect == .close {
                    self.cancel()
                }
                if let content = response.content {
                    do {
                        return try transformer.transform(input: content)
                    } catch {
                        return try self.handleError(transformer: transformer, error: error)
                    }
                } else {
                    return nil
                }
            case let .failure(error):
                return try self.handleError(transformer: transformer, error: error)
            }
        }
    }
    
    /// A `Publisher` and `Cancellable` that transforms each incoming `Result` using the
    /// given `transformer`.
    ///
    /// If the `transformer`'s ``ResultTransformer/handle(error:)`` returns
    /// ``ErrorHandlingStrategy/ignore``, no value is published. In case of
    /// ``ErrorHandlingStrategy/graceful(_:)`` the recovered value is published just
    /// as for `successful(_:)` input values. For ``ErrorHandlingStrategy/complete(_:)``
    /// the value is followed by a `.finished` completion. ``ErrorHandlingStrategy/abort(_:)``
    /// causes a completion with `.failure(_:)`.
    public func transform<T: ResultTransformer>(using transformer: T)
        -> CancellablePublisher<OpenCombine.Publishers.TryCompactMap<Self, T.Output>> where Result<T.Input, Error> == Output {
        self.tryCompactMap { result -> T.Output? in
            switch result {
            case let .success(response):
                do {
                    return try transformer.transform(input: response)
                } catch {
                    return try self.handleError(transformer: transformer, error: error)
                }
            case let .failure(error):
                return try self.handleError(transformer: transformer, error: error)
            }
        }
        .asCancellable {
            self.cancel()
        }
    }
    
    private func handleError<T: ResultTransformer>(transformer: T, error: Error) throws -> T.Output? {
        switch transformer.handle(error: error.apodiniError) {
        case .ignore:
            return nil
        case let .graceful(output):
            return output
        case let .complete(output):
            self.cancel()
            return output
        case let .abort(error):
            throw error
        }
    }
}


// MARK: Synchronous Error Handling

extension EventLoopFuture {
    /// Directly transforms any result using the given `transformer` except for a successfull completion
    /// where the `Response` has not `content`. In that case the future is completed with an internal
    /// server error.
    ///
    /// - Note: If the given `transformer`'s ``ResultTransformer/handle(error:)`` returns
    /// ``ErrorHandlingStrategy/ignore`` the future is completed with an internal server error.
    public func transform<T: ResultTransformer>(using transformer: T) -> EventLoopFuture<T.Output> where Response<T.Input> == Value {
        self.flatMapThrowing { response in
            if let content = response.content {
                return content
            } else {
                throw ApodiniError(
                    type: .serverError,
                    reason: "Missing Content",
                    description: "A 'Handler' that was used in a synchronous context returned a 'Response' without any 'Content'.")
            }
        }
        .transformContent(using: transformer)
    }
    
    /// Directly transforms any result using the given `transformer`.
    ///
    /// - Note: If the given `transformer`'s ``ResultTransformer/handle(error:)`` returns
    /// ``ErrorHandlingStrategy/ignore`` the future is completed with an internal server error.
    public func transform<T: ResultTransformer>(using transformer: T) -> EventLoopFuture<T.Output> where T.Input == Value {
        transformContent(using: transformer)
    }
    
    private func transformContent<T: ResultTransformer>(using transformer: T) -> EventLoopFuture<T.Output> where T.Input == Value {
        self.flatMapThrowing { content in
            do {
                return try transformer.transform(input: content)
            } catch {
                return try self.handleError(transformer, error)
            }
        }
        .flatMapErrorThrowing { error in
            return try self.handleError(transformer, error)
        }
    }
    
    private func handleError<T: ResultTransformer>(_ transformer: T, _ error: Error) throws -> T.Output {
        let error = error.apodiniError
        switch transformer.handle(error: error) {
        case let .graceful(output):
            return output
        case let .complete(output):
            return output
        case let .abort(failure):
            throw failure
        case .ignore:
            throw ApodiniError(type: .serverError, reason: "Unhandled Error", description: error.standardMessage)
        }
    }
}


// MARK: Error Messages

public extension Error {
    /// Returns a standard error message for this `Error` by transforming it to an
    /// `ApodiniError` and using its `.errorType` to obtain sensible message
    /// prefixes.
    var standardMessage: String {
        let error = self.apodiniError
        return error.message(with: standardMessagePrefix(for: error))
    }
    
    /// Returns a standard error message for this `Error` by transforming it to an
    /// `ApodiniError` using an empty prefix message.
    var unprefixedMessage: String {
        self.apodiniError.message(with: nil)
    }
}


private func standardMessagePrefix(for error: ApodiniError) -> String? {
    switch error.option(for: .errorType) {
    case .badInput:
        return "Bad Input"
    case .notFound:
        return "Resource Not Found"
    case .unauthenticated:
        return "Unauthenticated"
    case .forbidden:
        return "Forbidden"
    case .serverError:
        return "Unexpected Server Error"
    case .notAvailable:
        return "Resource Not Available"
    case .other:
        return "Error"
    }
}
