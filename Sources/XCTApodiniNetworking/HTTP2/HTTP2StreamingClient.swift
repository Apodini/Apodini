//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//  

import NIO
import NIOHTTP1
import NIOHTTP2
import NIOTLS
import NIOSSL
import Foundation
import NIOExtras

/// A client which can be used to test the HTTP/2 streaming patterns exported by the ``HTTPInterfaceExporter``.
/// ``StreamingDelegate``s can be attached to the client to send and receive on an individual HTTP/2 stream.
public class HTTP2StreamingClient {
    var connection: Channel?
    var eventLoop: EventLoop
    
    /// Initialize an ``HTTP2StreamingClient`` and connect it to the specified `host` and `port`
    public init(_ host: String, _ port: Int) throws {
        // MARK: Client Config, mainly about TLS
        var clientConfig = TLSConfiguration.makeClientConfiguration()
        clientConfig.applicationProtocols = ["h2"]
        clientConfig.certificateVerification = .none
        clientConfig.cipherSuites = "RSA+AESGCM"
        clientConfig.keyLogCallback = { buffer in
            let dir = FileManager.default.urls(
                for: FileManager.SearchPathDirectory.cachesDirectory,
                in: FileManager.SearchPathDomainMask.userDomainMask
            ).last!
            let fileurl = dir.appendingPathComponent("keylog.txt")

            let data = Data(buffer: buffer, byteTransferStrategy: .copy)

            if FileManager.default.fileExists(atPath: fileurl.path) {
                if let fileHandle = try? FileHandle(forWritingTo: fileurl) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                do {
                    try data.write(to: fileurl)
                } catch {
                    print("Can't write \(error)")
                }
            }
        }
        let sslContext = try NIOSSLContext(configuration: clientConfig)
        
        // MARK: Set up the connection
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)

        self.eventLoop = group.next()

        self.connection = try ClientBootstrap(group: eventLoop)
            .channelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .channelInitializer { channel in
                let sslHandler = try! NIOSSLClientHandler(context: sslContext, serverHostname: host)
                return channel.pipeline.addHandler(sslHandler).flatMap {
                    channel.configureHTTP2Pipeline(mode: .client) { channel in
                        channel.eventLoop.makeSucceededVoidFuture()
                    }
                    .map { (_: HTTP2StreamMultiplexer) in () }
                }
            }
            .connect(host: host, port: port)
            .wait()
    }
    
    /// Register a ``HTTPClientStreamingHandler`` on the passed `channel` for the `streamingDelegate`
    private func registerStreamingHandler<D: StreamingDelegate>(channel: Channel, streamingDelegate: D) -> EventLoopFuture<Channel> {
        // Step 1 is to find the HTTP2StreamMultiplexer so we can create HTTP/2 streams for our requests.
        channel.pipeline.handler(type: HTTP2StreamMultiplexer.self).flatMap { http2Multiplexer in
            // Step 2: Let's create the HTTP/2 stream.
            let promise = channel.eventLoop.makePromise(of: Channel.self)
            http2Multiplexer.createStreamChannel(promise: promise) { (streamChannel: Channel) in
                let handler = HTTPClientStreamingHandler(streamingDelegate: streamingDelegate)
                streamingDelegate.streamingHandler = handler
                return streamChannel.pipeline.addHandlers([
                    handler
                ], position: .last)
            }
            return promise.futureResult
        }
    }
    
    /// Attach a streaming delegate to the client by creating an HTTP/2 stream and starting the delegate's `handleStreamStart` method
    @discardableResult
    public func startStreamingDelegate<SD: StreamingDelegate>(_ delegate: SD) -> EventLoopFuture<Void> {
        guard let connection = connection else {
            return eventLoop.makeSucceededVoidFuture()
        }
        
        return self.registerStreamingHandler(channel: connection, streamingDelegate: delegate)
            .flatMap { streamChannel in
                streamChannel.closeFuture
            }
    }
    
    deinit {
        do {
            try connection?.close().wait()
        } catch {
            if let error = error as? ChannelError,
               error == .alreadyClosed {
                return
            }
            print(error)
        }
    }
}
