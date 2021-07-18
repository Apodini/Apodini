//
//  StatefulResultHandling.swift
//  
//
//  Created by Max Obermeier on 06.07.21.
//

import Foundation
import Apodini
import _Concurrency

extension AsyncSequence {
    /// An `AsyncSequence` that transforms each incoming `Result` using the given `transformer`
    /// after unwrapping the `Response` for `successful(_:)` input values.
    ///
    /// If a `Response` has no `content` it is absorbed. If the `Response`'s
    /// `connectionEffect` is `close`, the upstream pipeline is cancelled.
    ///
    /// If the `transformer`'s ``ResultTransformer/handle(error:)`` returns
    /// ``ErrorHandlingStrategy/ignore``, the element is absorbed. In case of
    /// ``ErrorHandlingStrategy/graceful(_:)`` the recovered value is passed downstream just
    /// as for `successful(_:)` input values. For ``ErrorHandlingStrategy/complete(_:)``
    /// the sequence ends after this final value. ``ErrorHandlingStrategy/abort(_:)``
    /// causes a the error to be thrown`.
    public func transform<T: ResultTransformer>(using transformer: T)
        -> AnyAsyncSequence<T.Output> where Element == Result<Response<T.Input>, Error> {
        self.cancel(if: { result in
            if case let .success(response) = result {
                return response.connectionEffect == .close
            }
            return false
        })
        .compactMap { result throws -> Result<T.Output, Error>? in
            switch result {
            case let .success(response):
                if let content = response.content {
                    do {
                        return .success(try transformer.transform(input: content))
                    } catch {
                        return .failure(error)
                    }
                } else {
                    return nil
                }
            case let .failure(error):
                return .failure(error)
            }
        }
        .handleError(using: transformer)
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
    public func transform<T: ResultTransformer, C: Encodable>(using transformer: T)
    -> AnyAsyncSequence<T.Output> where T.Input == Response<C>, Element == Result<Response<C>, Error> {
        self.cancel(if: { result in
            if case let .success(response) = result {
                return response.connectionEffect == .close
            }
            return false
        })
        .map { result throws -> Result<T.Output, Error> in
            switch result {
            case let .success(response):
                do {
                    return .success(try transformer.transform(input: response))
                } catch {
                    return .failure(error)
                }
            case let .failure(error):
                return .failure(error)
            }
        }
        .handleError(using: transformer)
    }
}

private extension AsyncSequence {
    func handleError<T: ResultTransformer>(using transformer: T) -> AnyAsyncSequence<T.Output> where Element == Result<T.Output, Error> {
        self
            .compactMap { result throws -> (Bool, T.Output)? in
                switch result {
                case let .success(output):
                    return (false, output)
                case let .failure(error):
                    switch transformer.handle(error: error.apodiniError) {
                    case .ignore:
                        return nil
                    case let .abort(error):
                        throw error
                    case let .complete(output):
                        return (true, output)
                    case let .graceful(output):
                        return (false, output)
                    }
                }
            }
            .cancel(if: { cancel, _ in cancel })
            .map { _, output in output }
            .typeErased
    }
}
