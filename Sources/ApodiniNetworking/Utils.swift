//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import ApodiniHTTPProtocol
import ApodiniUtils
import Foundation


extension ByteBuffer {
    /// Reads all data currently in the byte buffer, without moving the reader index (i.e. non-consuming).
    public func getAllData() -> Data? {
        self.getData(at: 0, length: self.writerIndex)
    }
    
    /// Reads all bytes currently in the byte buffer, without moving the reader index (i.e. non-consuming).
    public func getAllBytes() -> [UInt8]? { // swiftlint:disable:this discouraged_optional_collection
        self.getBytes(at: 0, length: self.writerIndex)
    }
}


extension HTTPResponseStatus {
    /// Creates a `HTTPResponseStatus` based on an `Apodini.Status`.
    public init(_ status: Apodini.Status) {
        switch status {
            // 200
        case .ok:
            self = .ok
        case .created:
            self = .created
        case .noContent:
            self = .noContent
        case .accepted:
            self = .accepted
            // 300
        case .redirect:
            self = .seeOther
        case .notModified:
            self = .notModified
        }
    }
}


extension HTTPVersion {
    /// Attempts to create a version object from a string
    public init?(string: String) {
        switch string {
        case "2", "2.0", "HTTP/2", "HTTP/2.0":
            self = .http2
        case "1", "1.0", "HTTP/1", "HTTP/1.0":
            self = .http1_0
        case "1.1", "HTTP/1.1":
            self = .http1_1
        case "0.9", "HTTP/0.9":
            self = .http0_9
        case "3", "3.0", "HTTP/3", "HTTP/3.0":
            self = .http3
        default:
            return nil
        }
    }
}


extension HTTPMethod {
    /// Creates a `HTTPMethod` based on an `Apodini.Operation`
    public init(_ operation: Apodini.Operation) {
        switch operation {
        case .create:
            self =  .POST
        case .read:
            self =  .GET
        case .update:
            self =  .PUT
        case .delete:
            self =  .DELETE
        }
    }
}


extension HTTPHeaders {
    /// Initialises a `HTTPHeaders` object with the contents of the specified `InformationSet`
    public init(_ information: InformationSet) {
        self.init(information.compactMap { ($0 as? HTTPHeaderInformationClass)?.entry })
    }
}


extension EventLoopFuture {
    /// Maps the future into another future, giving the caller the opportunity to map both success and failure values
    public func flatMapAlways<NewValue>(
        file: StaticString = #file,
        line: UInt = #line,
        _ block: @escaping (Result<Value, Error>) -> EventLoopFuture<NewValue>
    ) -> EventLoopFuture<NewValue> {
        let promise = self.eventLoop.makePromise(of: NewValue.self, file: file, line: line)
        self.whenComplete { block($0).cascade(to: promise) }
        return promise.futureResult
    }
    
    /// Runs the specified block when the future is completed, regardless of whether the result is a success or a failure
    public func inspect(_ block: @escaping (Result<Value, Error>) -> Void) -> EventLoopFuture<Value> {
        self.whenComplete(block)
        return self
    }
    
    /// Runs the specified block when the future succeeds
    public func inspectSuccess(_ block: @escaping (Value) -> Void) -> EventLoopFuture<Value> {
        self.whenSuccess(block)
        return self
    }
    
    /// Runs the specified block when the future fails
    public func inspectFailure(_ block: @escaping (Error) -> Void) -> EventLoopFuture<Value> {
        self.whenFailure(block)
        return self
    }
}


extension AsyncSequence {
    /// Returns an `EventLoopFuture` which will fulfill with the first element in the sequence, and also calls the specified closure once with every element in the sequence
    public func firstFutureAndForEach(on eventLoop: EventLoop, objectsHandler: @escaping (Element) -> Void) -> EventLoopFuture<Element?> {
        let promise = eventLoop.makePromise(of: Element?.self)
        Task {
            var idx = 0
            for try await element in self {
                if idx == 0 {
                    promise.succeed(element)
                }
                idx += 1
                objectsHandler(element)
            }
            if idx == 0 {
                promise.succeed(nil)
            }
        }
        return promise.futureResult
    }
}
