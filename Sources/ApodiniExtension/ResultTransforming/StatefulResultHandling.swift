//
//  StatefulResultHandling.swift
//  
//
//  Created by Max Obermeier on 06.07.21.
//

import Foundation
import Apodini
import OpenCombine

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
