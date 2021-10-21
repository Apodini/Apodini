import NIO
import ApodiniUtils
import Foundation


/// A type which can be written to a `ByteBuffer`
public protocol __LKByteBufferWritable {
    func write(to byteBuffer: inout ByteBuffer)
}


extension String: __LKByteBufferWritable {
    public func write(to byteBuffer: inout ByteBuffer) {
        byteBuffer.writeString(self)
    }
}


extension Data: __LKByteBufferWritable {
    public func write(to byteBuffer: inout ByteBuffer) {
        byteBuffer.writeData(self)
    }
}


extension ByteBuffer: __LKByteBufferWritable {
    public func write(to byteBuffer: inout ByteBuffer) {
        var selfCopy = self // TODO this is bad insofar as it doesn't move the actual self's readerIndex
        // But the alternative would be to make the `write(to:)` function mutable, which would mean that we can only ever write references, which is also extremely limiting
        // TODO come up w/ some nice solution for this!
        byteBuffer.writeBuffer(&selfCopy)
    }
}



extension NSLocking {
    func withLock<Result>(_ fn: () -> Result) -> Result {
        lock()
        defer { unlock() }
        return fn()
    }
}



public final class LKDataStream {
    public typealias ObserverFn = (LKDataStream, Event) -> Void
    
    public enum Event {
        /// New data was written to the stream, and the stream is still open
        case write
        /// The stream has been closed, and no new data has been written since the last time the observer was called
        case close
        /// New data has been written to the stream, and the stream is now closed
        case writeAndClose
    }
    
    static private(set) var streamAllocCount = 0
    
    public var debugName: String = "Stream"
    
    private let lock = NSRecursiveLock()
    private var storage: ByteBuffer
    private(set) public var isClosed = false
    private var observer: ObserverFn?
    
    // Same as storage but there's no locking or thread safety for reading the data
    public var unsafeStorage: ByteBuffer { storage }
    
    
    public init(capacity: Int = 0) {
        storage = ByteBufferAllocator().buffer(capacity: capacity)
        Self.streamAllocCount += 1
        print("streamAllocCount", Self.streamAllocCount)
    }
    
    deinit {
        // TODO we have a retain cycle somewhere here!
        Self.streamAllocCount -= 1
        print("streamAllocCount", Self.streamAllocCount)
    }
    
    
    /// Sets the stream's observer function.
    /// The observer gets called when certain events occur on the stream, such as the stream being written to or closed
    /// - Note: Pass nil to remove the current observer. The observer will automatically be removed when the stream is closed, since no further events will occur
    /// - Note: Registering an observer on an already-closed stream will invoke the observer once (with the `.close` event), and then remove the observer from the stream
    public func setObserver(_ fn: ObserverFn?) {
        //lock.withLock { print("Setting new observer on \(Unmanaged.passUnretained(self).toOpaque())"); observer = fn }
        lock.withLock {
            if isClosed {
                fn?(self, .close)
                observer = nil
            } else {
                observer = fn
            }
        }
    }
    
    
    public var readableBytes: Int {
        storage.readableBytes
    }
    
    
    public func write<T: __LKByteBufferWritable>(_ data: T) {
        lock.withLock {
            precondition(!isClosed, "Cannot write to closed stream")
            data.write(to: &storage)
            observer?(self, .write)
        }
    }
    
    public func writeAndClose<T: __LKByteBufferWritable>(_ data: T) {
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
    
    public func readNewData() -> ByteBuffer? {
        lock.withLock {
            storage.readSlice(length: storage.readableBytes)
        }
    }
    
    internal func mutateStorage<Result>(_ block: (inout ByteBuffer) -> Result) -> Result {
        lock.withLock {
            block(&self.storage)
        }
    }
}



/// A container storing the body of a HTTP request or response, supporting both buffer and stream-based requests and responses
/// - Note: Regarding the terminology of the methods declared on this type, we differentiate between the following:
///         - methods starting with `get`: these are non-consuming and will return the entire contents of the storage
///         - methods starting with `read`: these are consuming, and will a) return the contents of the storate written since the last read,
///             and b) move the storage's reader index to the end.
public enum LKRequestResponseBodyStorage {
    case buffer(ByteBuffer)
    case stream(LKDataStream)
    
    
    /// Creates a buffer-based body stirage with a newly initialised buffer object
    public static func buffer(initialCapacity: Int = 0) -> Self {
        .buffer(ByteBufferAllocator().buffer(capacity: initialCapacity))
    }
    
    /// Creates a stream-based body storage with a newly initialised stream object
    public static func stream(initialCapacity: Int = 0) -> Self {
        .stream(LKDataStream(capacity: initialCapacity))
    }
    
    public static func buffer<T: __LKByteBufferWritable>(initialValue: T) -> Self {
        var buffer = Self.buffer(ByteBuffer())
        buffer.write(initialValue)
        return buffer
    }
    
    public static func stream<T: __LKByteBufferWritable>(initialValue: T) -> Self {
        var stream = Self.stream(LKDataStream())
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
    
    
    public func getFullBodyDataAsString(encoding: String.Encoding = .utf8) -> String? {
        return getFullBodyData().flatMap { String(data: $0, encoding: encoding) }
    }
    
    /// Reads new data that has been added to the body since the last time this function was called
    public mutating func readNewData() -> Data? {
        return visitMutating(
            buffer: { $0.readData(length: $0.readableBytes) },
            stream: { $0.readNewData().flatMap { $0.getData(at: 0, length: $0.readableBytes) } }
        )
    }
    
    
    public mutating func readNewDataAsString(encoding: String.Encoding = .utf8) -> String? {
        return readNewData().flatMap { String(data: $0, encoding: encoding) }
    }
    
    
    /// Attempts to decode an object of the specified type from the full body data, using the specified decoder.
    /// - Note: This function does **NOT** move the body's reader index.
    public func getFullBodyData<T: Decodable>(decodedAs _: T.Type, using decoder: AnyDecoder = JSONDecoder()) throws -> T {
        return try decoder.decode(T.self, from: getFullBodyData() ?? Data())
    }
    
    /// Attempts to decode the new data to the specified type.
    /// Note that this is probably somewhat useless since the new data would have to not be a chunk or some kind of partial object.
    public mutating func readNewData<T: Decodable>(decodedAs _: T.Type, using decoder: AnyDecoder = JSONDecoder()) throws -> T {
        return try decoder.decode(T.self, from: readNewData() ?? Data())
    }
    
    
    /// Writes the specified value to the underlying storage
    public mutating func write<T: __LKByteBufferWritable>(_ value: T) {
        visitMutating(
            buffer: { value.write(to: &$0) },
            stream: { $0.write(value) }
        )
    }
    
    
    /// Writes the specified value to the storage, encoding it using the specified encoder
    public mutating func write<T: Encodable>(encoding value: T, using encoder: AnyEncoder = JSONEncoder()) throws {
        write(try encoder.encode(value))
    }
    
    
    public var isStream: Bool {
        return stream != nil
    }
    
    /// Returns the underlying stream, if applicable
    public var stream: LKDataStream? {
        switch self {
        case .buffer:
            return nil
        case .stream(let stream):
            return stream
        }
    }
    
    
    public var readableBytes: Int {
        switch self {
        case .buffer(let buffer):
            return buffer.readableBytes
        case .stream(let stream):
            return stream.unsafeStorage.readableBytes
        }
    }
    
    
    private mutating func visitMutating<Result>(
        buffer visitBuffer: (inout ByteBuffer) throws -> Result,
        stream visitStream: (LKDataStream) throws -> Result
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
    
    
    public mutating func reserveCapacity(_ capacity: Int) {
        visitMutating(
            buffer: { $0.reserveCapacity(capacity) },
            stream: { $0.mutateStorage { $0.reserveCapacity(capacity) } }
        )
    }
}

