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


extension AnyEncoder {
    /// Type-safe HTTP media type this encoder would encode into.
    public var resultMediaType: HTTPMediaType? {
        self.resultMediaTypeRawValue.flatMap { .init(string: $0) }
    }
}


extension ByteBuffer {
    /// Reads all data currently in the byte buffer, without moving the reader index (i.e. non-consuming).
    public func getAllData() -> Data? {
        self.getData(at: 0, length: self.writerIndex)
    }
}


extension HTTPResponseStatus {
    /// Creates a `HTTPResponseStatus` based on an `Apodini.Status`.
    public init(_ status: Apodini.Status) {
        switch status {
        case .ok:
            self = .ok
        case .created:
            self = .created
        case .noContent:
            self = .noContent
        case .redirect:
            self = .seeOther
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
}
