//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
import Foundation
import Apodini


extension EventLoopFuture {
    /// Directly transforms any result using the given `transformer` except for a successful completion
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
