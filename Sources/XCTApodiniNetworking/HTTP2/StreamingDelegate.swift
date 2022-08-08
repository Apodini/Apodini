//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

/// A delegate which receives responses from an HTTP server speaking the HTTP/2 length-prefixed streaming protocol
public protocol StreamingDelegate: AnyObject {
    associatedtype SRequest: Encodable
    associatedtype SResponse: Decodable
    
    var streamingHandler: HTTPClientStreamingHandler<Self>? { get set }
    var headerFields: BasicHTTPHeaderFields { get }
    
    func sendOutbound(request: SRequest)
    func close()
    
    func handleInbound(response: SResponse, serverSideClosed: Bool)
    func handleStreamStart()
}

public extension StreamingDelegate {
    /// Send a request to the server
    func sendOutbound(request: SRequest) {
        streamingHandler?.sendOutbound(request: request)
    }
    
    /// Close the HTTP/2 stream
    func close() {
        streamingHandler?.close()
    }
}
