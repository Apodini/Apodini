import Apodini
import ApodiniHTTPProtocol
import ApodiniUtils
import Foundation


extension AnyEncoder {
    public var resultMediaType: HTTPMediaType? {
        return self.resultMediaTypeRawValue.flatMap { .init(string: $0) }
    }
}


extension ByteBuffer {
    /// Reads all data currently in the byte buffer, without moving the reader index (i.e. non-consuming).
    public func getAllData() -> Data? {
        return self.getData(at: 0, length: self.writerIndex)
    }
}


extension HTTPResponseStatus {
    /// Creates a `Vapor``HTTPStatus` based on an `Apodini` `Status`.
    /// - Parameter status: The `Apodini` `Status` that should be transformed in a `Vapor``HTTPStatus`
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
    /// Creates a `Vapor``HTTPMethod` based on an `Apodini` `Operation`.
    /// - Parameter operation: The `Apodini` `Operation` that should be transformed in a `Vapor``HTTPMethod`
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
    /// Creates a `Vapor``HTTPHeaders` instance based on an `Apodini` `Information` array.
    /// - Parameter information: The `Apodini` `Information` array that should be transformed in a `Vapor``HTTPHeaders` instance
    public init(_ information: InformationSet) {
        self.init(information.compactMap { ($0 as? HTTPHeaderInformationClass)?.entry })
    }
}


extension EventLoopFuture {
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
