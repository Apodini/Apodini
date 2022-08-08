//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import ApodiniNetworking
import Foundation

/// An ``AsyncSequence`` which emits ``Data`` objects of serialized JSON.
/// The ``Data`` objects are created by reading length-prefixed blocks from an ``HTTPRequest``'s stream body storage.
///
/// This is used for streaming ``CommunicationPatterns`` via HTTP/2 DATA frames.
class HTTPRequestStreamAsyncSequence: AsyncSequence, AsyncIteratorProtocol {
    typealias Element = Data
    
    var stream: BodyStorage.Stream
    
    init(_ stream: BodyStorage.Stream) {
        self.stream = stream
    }
    
    func next() async throws -> Element? {
        // We expect the stream to always point at the Int32
        // indicating the beginning of the next object.

        // If there's an object in the stream, we emit it.
        // Even if the stream has been closed already.
        if let data = readObjectFromStream() {
            return data
        }
        
        // The stream has been closed and there is no complete object on the stream.
        // This is the end of the AsyncSequence.
        if stream.isClosed {
            print("Ending AsyncSequence")
            return nil
        }
        
        // The stream is not closed, but there's also not a complete object on the stream.
        // We wait until the next stream event.
        var dataObject: Data?
        repeat {
            await awaitStreamEvent()
            dataObject = readObjectFromStream()
        } while dataObject == nil && !stream.isClosed
        
        guard let dataObject = dataObject else {
            // The stream has been closed.
            return nil
        }

        return dataObject
    }
    
    private func awaitStreamEvent() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            if stream.isClosed {
                continuation.resume()
                return
            }
            stream.setObserver { _, _ in
                self.stream.removeObserver()
                continuation.resume()
            }
        }
    }
    
    /// Tries to read a ``Data`` object of the expected length from the stream and moves the reader index.
    /// Returns nil if the stream is not long enough.
    private func readObjectFromStream() -> Data? {
        // We get the integer and check whether the stream is long enough.
        guard let int32ByteBuffer = stream.getBytes(4),
              let objectLengthInt32 = int32ByteBuffer.getInteger(at: 0, as: Int32.self),
              stream.readableBytes >= objectLengthInt32 + 4 else {
            return nil
        }
        
        let objectLength = Int(objectLengthInt32)
        
        guard let int32AndObjectByteBuffer = stream.readBytes(objectLength + 4) else {
            print("Something is pretty wrong. The stream said it's long enough, but we can't read as much as we're supposed to.")
            return nil
        }
        
        guard let data = int32AndObjectByteBuffer.getData(at: 4, length: objectLength) else {
            print("Something is pretty wrong. We can't read as much data as we would like to.")
            return nil
        }
        
        return data
    }
    
    func makeAsyncIterator() -> HTTPRequestStreamAsyncSequence {
        self
    }
}
