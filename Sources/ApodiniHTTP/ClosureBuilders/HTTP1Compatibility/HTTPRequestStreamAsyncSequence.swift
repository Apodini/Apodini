//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import ApodiniNetworking

/// An ``AsyncSequence`` which emits ``Data`` objects of serialized JSON.
/// The ``Data`` objects are created by reading length-prefixed blocks from an ``HTTPRequest``'s stream body storage.
///
/// This is used for streaming ``CommunicationPatterns`` via HTTP/2 DATA frames.
class HTTPRequestStreamAsyncSequence: AsyncSequence, AsyncIteratorProtocol {
    typealias Element = Data
    
    var stream: BodyStorage.Stream
    var streamClosed = false
    
    init(_ request: HTTPRequest) {
        guard case .stream(let stream) = request.bodyStorage else {
            fatalError("Cannot construct an AsyncSequence from a non-streaming request body")
        }
        
        self.request = request
        self.stream = stream
        
        self.stream.setObserver { stream, event in
            self.events.append(event)
        }
    }
    
    func next() async throws -> Element? {
        defer {
            print("Incrementing event index in AsyncSequence")
            nextEventIndex += 1
        }
        
        if streamClosed {
            print("Returning nil after .writeAndClose")
            return nil
        }
        
        while nextEventIndex == events.count {
            await Task.yield()
            //try await Task.sleep(nanoseconds: 100_000_000)
        }
        let latestEvent = events[nextEventIndex]
        if latestEvent == .close  {
            print("Returning nil after .close")
            return nil
        } else if latestEvent == .writeAndClose {
            print("AsyncSequence sees that stream was closed")
            streamClosed = true
        }
        print("Yielding request from asyncsequence as stream has been written to")
        print("Current Body data: \(request.bodyStorage.getFullBodyDataAsString())")
        return request
    }
    
    func makeAsyncIterator() -> HTTPRequestStreamAsyncSequence {
        self
    }
}
