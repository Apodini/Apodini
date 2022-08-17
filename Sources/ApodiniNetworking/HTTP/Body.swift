//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import NIO
import ApodiniUtils
import Foundation


/// A type which can be written to a `ByteBuffer`
public protocol ByteBufferWritable {
    /// Writes the receiver into the specified byte buffer
    func write(to byteBuffer: inout ByteBuffer)
}


extension String: ByteBufferWritable {
    public func write(to byteBuffer: inout ByteBuffer) {
        byteBuffer.writeString(self)
    }
}


extension Data: ByteBufferWritable {
    public func write(to byteBuffer: inout ByteBuffer) {
        byteBuffer.writeData(self)
    }
}


extension Array: ByteBufferWritable where Element == UInt8 {
    public func write(to byteBuffer: inout ByteBuffer) {
        byteBuffer.writeBytes(self)
    }
}

extension Int32: ByteBufferWritable {
    public func write(to byteBuffer: inout ByteBuffer) {
        byteBuffer.writeInteger(self, as: Int32.self)
    }
}


extension ByteBuffer: ByteBufferWritable {
    public func write(to byteBuffer: inout ByteBuffer) {
        // Note: This is somewhat limiting insofar as it operates on a copy, which means that `self`s reader index won't be moved forward by the read number of bytes.
        // There isn't really much we can do about this, though, since addressing this would reqire making the function mutable in the protocol definition, which would also require us to make all other places this is used mutating, which would have a much greater impact than the current workaround.
        var selfCopy = self
        byteBuffer.writeBuffer(&selfCopy)
    }
}


/// A container storing the body of a HTTP request or response, supporting both buffer and stream-based requests and responses
/// - Note: Regarding the terminology of the methods declared on this type, we differentiate between the following:
///         - methods starting with `get`: these are non-consuming and will return the entire contents of the storage
///         - methods starting with `read`: these are consuming, and will a) return the contents of the storate written since the last read,
///             and b) move the storage's reader index to the end.
public enum BodyStorage {
    /// A buffer-backed body storage
    case buffer(ByteBuffer)
    /// A stream-backed body storage
    case stream(Stream)
    
    
    /// Creates a buffer-based body storage with a newly initialised buffer object
    public static func buffer(initialCapacity: Int = 0) -> Self {
        .buffer(ByteBufferAllocator().buffer(capacity: initialCapacity))
    }
    
    /// Creates a stream-based body storage with a newly initialised stream object
    public static func stream(initialCapacity: Int = 0) -> Self {
        .stream(Stream(capacity: initialCapacity))
    }
    
    /// Creates a buffer-based body storage, and writes the specified initial value to that buffer.
    public static func buffer<T: ByteBufferWritable>(initialValue: T) -> Self {
        var buffer = Self.buffer(ByteBuffer())
        buffer.write(initialValue)
        return buffer
    }
    
    /// Creates a stream-based body storage, and writes the specified initial value to that stream.
    public static func stream<T: ByteBufferWritable>(initialValue: T) -> Self {
        var stream = Self.stream(Stream())
        stream.write(initialValue)
        return stream
    }
    
    /// Returns the full contents of the body, ignoring the current reader index (if applicable)
    public func getFullBodyData() -> Data? {
        switch self {
        case .buffer(let byteBuffer):
            return byteBuffer.getData(at: 0, length: byteBuffer.writerIndex)
        case .stream(let stream):
            return stream.unsafeStorage.getData(at: 0, length: stream.unsafeStorage.writerIndex)
        }
    }
    
    /// Returns the full contents of the body (decoded as a string), ignoring the current reader index (if applicable)
    /// - parameter encoding: The string encoding to use
    public func getFullBodyDataAsString(encoding: String.Encoding = .utf8) -> String? {
        getFullBodyData().flatMap { String(data: $0, encoding: encoding) }
    }
    
    /// Reads new data that has been added to the body since the last time this function was called
    public mutating func readNewData() -> Data? {
        visitMutating(
            buffer: { $0.readData(length: $0.readableBytes) },
            stream: { $0.readNewData().flatMap { $0.getData(at: 0, length: $0.readableBytes) } }
        )
    }
    
    
    /// Reads, decoded as a string, all new data written to the storage since the last read
    /// - parameter encoding: The string encoding to use
    public mutating func readNewDataAsString(encoding: String.Encoding = .utf8) -> String? {
        readNewData().flatMap { String(data: $0, encoding: encoding) }
    }
    
    
    /// Attempts to decode an object of the specified type from the full body data, using the specified decoder.
    /// - Note: This function does **NOT** move the body's reader index.
    public func getFullBodyData<T: Decodable>(decodedAs _: T.Type, using decoder: AnyDecoder = JSONDecoder()) throws -> T {
        try decoder.decode(T.self, from: getFullBodyData() ?? Data())
    }
    
    /// Attempts to decode the new data to the specified type.
    /// Note that this is probably somewhat useless since the new data would have to not be a chunk or some kind of partial object.
    public mutating func readNewData<T: Decodable>(decodedAs _: T.Type, using decoder: AnyDecoder = JSONDecoder()) throws -> T {
        try decoder.decode(T.self, from: readNewData() ?? Data())
    }
    
    
    /// Writes the specified value to the underlying storage
    public mutating func write<T: ByteBufferWritable>(_ value: T) {
        visitMutating(
            buffer: { value.write(to: &$0) },
            stream: { $0.write(value) }
        )
    }
    
    
    /// Writes the specified value to the storage, encoding it using the specified encoder
    public mutating func write<T: Encodable>(encoding value: T, using encoder: AnyEncoder = JSONEncoder()) throws {
        write(try encoder.encode(value))
    }
    
    
    /// Returns `true` iff the underlying storage is a stream, otherwise `false`.
    public var isStream: Bool {
        stream != nil
    }
    
    /// Returns `true` iff the underlying storage is a buffer, otherwise `false`.
    public var isBuffer: Bool {
        stream == nil
    }
    
    /// Returns the underlying stream, if applicable
    public var stream: Stream? {
        switch self {
        case .buffer:
            return nil
        case .stream(let stream):
            return stream
        }
    }
    
    
    /// The amount of readable bytes in the storage
    public var readableBytes: Int {
        switch self {
        case .buffer(let buffer):
            return buffer.readableBytes
        case .stream(let stream):
            return stream.unsafeStorage.readableBytes
        }
    }
    
    
    /// Internal helper function that essentially acts as a visitor for mutating the different kinds of underlying storage types
    private mutating func visitMutating<Result>(
        buffer visitBuffer: (inout ByteBuffer) throws -> Result,
        stream visitStream: (Stream) throws -> Result
    ) rethrows -> Result {
        switch self {
        case .buffer(var buffer):
            let result = try visitBuffer(&buffer)
            self = .buffer(buffer)
            return result
        case .stream(let stream):
            return try visitStream(stream)
        }
    }
    
    
    /// Reserves enough capasity to store at least the specified about of bytes.
    /// - parameter capacity: The number of bytes you want to be able to store. This includes bytes already stored in the storage.
    public mutating func reserveCapacity(_ capacity: Int) {
        visitMutating(
            buffer: { $0.reserveCapacity(capacity) },
            stream: { $0.mutateStorage { $0.reserveCapacity(capacity) } }
        )
    }
}


extension BodyStorage {
    /// A Stream object which can be used to read or write from or to a stream of data.
    /// - Note: Since streams are potentially accessed from within the context of some asynchronous operation, this class is implemented somewhat Thread-Safe.
    public final class Stream {
        /// Stream observer
        public typealias ObserverFn = (Stream, Event) -> Void
        
        /// An event that describes a mutation made to the stream.
        public enum Event {
            /// New data was written to the stream, and the stream is still open
            case write
            /// The stream has been closed, and no new data has been written since the last time the observer was called
            case close
            /// New data has been written to the stream, and the stream is now closed
            case writeAndClose
        }
        
        private let lock = NSRecursiveLock()
        private var storage: ByteBuffer
        /// Whether the stream has been closed.
        /// Once a stream is closed, it cannot be re-opened, meaning that this is a guarantee that the stream wont receive any new data.
        public private(set) var isClosed = false
        private var observer: ObserverFn?
        
        /// Same as storage but there's no locking or thread safety for reading the data
        public var unsafeStorage: ByteBuffer { storage }
        
        /// Creates a new stream object
        public init(capacity: Int = 0) {
            storage = ByteBufferAllocator().buffer(capacity: capacity)
        }
        
        
        /// Sets the stream's observer function.
        /// The observer gets called when certain events occur on the stream, such as the stream being written to or closed
        /// - Note: Pass nil to remove the current observer. The observer will automatically be removed when the stream is closed, since no further events will occur
        /// - Note: Registering an observer on an already-closed stream will invoke the observer once (with the `.close` event), and then remove the observer from the stream
        public func setObserver(allowOverwritingExistingObserver: Bool = false, _ block: ObserverFn?) {
            lock.withLock {
                if isClosed {
                    precondition(self.observer == nil || block == nil)
                    block?(self, .close)
                } else {
                    precondition(observer == nil || allowOverwritingExistingObserver, "Attempted to set an observer on a stream that already has an observer registered. If this is something you actually want (which probably isn't the case, considering that a stream can only have one observer, and that existing other observer would now no longer receive stream events), you can use the 'allowOverwritingExistingObserver' parameter to explicitly enable this behaviour.") // swiftlint:disable:this line_length
                    observer = block
                }
            }
        }
        
        /// Remove the observer from the stream
        public func removeObserver() {
            lock.withLock {
                self.observer = nil
            }
        }
        
        
        /// The number of readable bytes in the stream.
        public var readableBytes: Int {
            storage.readableBytes
        }
        
        /// Writes some data to the stream, and (if applicable) informs the observer that new data can be read
        public func write<T: ByteBufferWritable>(_ data: T) {
            print("Will write data of type \(T.self) with lock")
            // Note ideally this (and the other mutating write functions) would also take a promise/future parameter, or return smth; that would allow us to control when data is written to the stream.
            // Otherwise we could, for very large streams, eventually run out of memory, which would be somewhat suboptimal
            lock.withLock {
                precondition(!isClosed, "Cannot write to closed stream")
                data.write(to: &storage)
                if let buf = data as? ByteBuffer {
                    print("Writing ByteBuffer of length \(buf.readableBytes): \(buf.getString(at: 0, length: buf.readableBytes))")
                }
                if let dat = data as? Data {
                    print("Writing Data of length \(dat.count)")
                }
                if observer == nil {
                    print("No stream observer set, not calling anything\n")
                } else {
                    print("Calling stream observer")
                }
                observer?(self, .write)
            }
        }
        
        /// Write some data to the stream and close it, in a single operation
        /// Writes some data to the stream, and (if applicable) informs the observer that new data can be read
        public func writeAndClose<T: ByteBufferWritable>(_ data: T) {
            lock.withLock {
                precondition(!isClosed, "Cannot write to closed stream")
                data.write(to: &storage)
                isClosed = true
                observer?(self, .writeAndClose)
                setObserver(nil)
            }
        }
        
        /// Closes the stream, and informs the delegate that no further bytes will be written
        public func close() {
            lock.withLock {
                precondition(!isClosed, "Cannot close stream more than once")
                isClosed = true
                observer?(self, .close)
                setObserver(nil)
            }
        }
        
        /// Reads `length` bytes from the stream.
        public func readBytes(_ length: Int) -> ByteBuffer? {
            lock.withLock {
                storage.readSlice(length: length)
            }
        }
        
        /// Gets `length` bytes from the stream. Doesn't move the readIndex in the underlying `ByteBuffer`.
        public func getBytes(_ length: Int) -> ByteBuffer? {
            lock.withLock {
                storage.getSlice(at: storage.readerIndex, length: length)
            }
        }
        
        /// Reads new data from the stream, if available.
        public func readNewData() -> ByteBuffer? {
            lock.withLock {
                storage.readSlice(length: storage.readableBytes)
            }
        }
        
        /// Reads new data from the stream, if available. Doesn't move the readIndex in the underlying `ByteBuffer`.
        public func getNewData() -> ByteBuffer? {
            lock.withLock {
                storage.getSlice(at: storage.readerIndex, length: storage.readableBytes)
            }
        }
        
        internal func mutateStorage<Result>(_ block: (inout ByteBuffer) -> Result) -> Result {
            lock.withLock {
                block(&self.storage)
            }
        }
        
        /// Collects the contents of the stream into a `ByteBuffer`.
        /// - returns: An `EventLoopFuture` to a `ByteBuffer` containing the contents of the stream, which will fulfill when the stream is closed.
        ///         If the stream is already closed, the future will succeed to an empty buffer.
        /// - Note: This function registers an observer on the stream.
        public func collect(on eventLoop: EventLoop) -> EventLoopFuture<ByteBuffer> {
            guard !self.isClosed else {
                return eventLoop.makeSucceededFuture(ByteBuffer())
            }
            let promise = eventLoop.makePromise(of: ByteBuffer.self)
            let collectedBytes = Box(ByteBuffer())
            self.setObserver { stream, _ in
                if let newData = stream.readNewData() {
                    collectedBytes.value.writeImmutableBuffer(newData)
                }
                if stream.isClosed {
                    promise.succeed(collectedBytes.value)
                }
            }
            return promise.futureResult
        }
    }
}
