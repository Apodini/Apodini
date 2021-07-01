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

public protocol ResultTransformer {
    associatedtype Input
    associatedtype Output
    associatedtype Failure: Error
    
    func handle(error: ApodiniError) -> ErrorHandlingStrategy<Output, Failure>
    func transform(input: Input) throws -> Output
}

public enum ErrorHandlingStrategy<Output, Failure: Error> {
    case graceful(Output)
    case ignore
    case abort(Failure)
    case complete(Output)
}


// MARK: Asynchronous Error Handling

extension CancellablePublisher {
    public func transform<T: ResultTransformer>(using transformer: T) -> OpenCombine.Publishers.TryCompactMap<Self, T.Output> where Result<Response<T.Input>, Error> == Output {
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
    
    public func transform<T: ResultTransformer>(using transformer: T) -> CancellablePublisher<OpenCombine.Publishers.TryCompactMap<Self, T.Output>> where Result<T.Input, Error> == Output {
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
        }.asCancellable {
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
    public func transform<T: ResultTransformer>(using transformer: T) -> EventLoopFuture<T.Output> where Response<T.Input> == Value {
        self.flatMapThrowing { response in
            if let content = response.content {
                return content
            } else {
                throw ApodiniError(type: .serverError,
                                   reason: "Missing Content",
                                   description: "A 'Handler' that was used in a synchronous, EventLoopFuture based context returned a 'Response' that did not contain any 'Content'.")
            }
        }
        .transformContent(using: transformer)
    }
    
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
        }.flatMapErrorThrowing { error in
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
    var standardMessage: String {
        let error = self.apodiniError
        return error.message(with: standardMessagePrefix(for: error))
    }
    
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
