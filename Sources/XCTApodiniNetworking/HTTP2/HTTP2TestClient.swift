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
public class HTTP2TestClient {
    // MARK: Singleton pattern
    /// The default HTTP2TestClient used to connect to the server
    public static let client: HTTP2TestClient = {
        do {
            return try .init()
        } catch {
            fatalError("dead")
        }
    }()
    
    // MARK: Connection details
    static let host = "localhost"
    static let port = 443
    
    var numberOfErrors = 0
    var bootstrap: ClientBootstrap?
    var eventLoop: EventLoop
    
    private init() throws {
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
        
        // MARK: Set up the connection bootstrap
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)

        self.eventLoop = group.next()

        self.bootstrap = ClientBootstrap(group: eventLoop)
            .channelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .channelInitializer { channel in
                let sslHandler = try! NIOSSLClientHandler(context: sslContext, serverHostname: HTTP2TestClient.host)
                return channel.pipeline.addHandler(sslHandler).flatMap {
                    channel.configureHTTP2Pipeline(mode: .client) { channel in
                        channel.eventLoop.makeSucceededVoidFuture()
                    }
                    .map { (_: HTTP2StreamMultiplexer) in () }
                }
            }
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
    public func startStreamingDelegate<SD: StreamingDelegate>(_ delegate: SD) throws -> EventLoopFuture<Void> {
        guard let bootstrap = self.bootstrap else {
            return eventLoop.makeSucceededVoidFuture()
        }
        
        return bootstrap.connect(host: "localhost", port: 4443)
            .flatMap { channel in
                self.registerStreamingHandler(channel: channel, streamingDelegate: delegate)
                    .and(value: channel)
            }
            .flatMap { streamChannel, channel in
                streamChannel.closeFuture.map {
                    channel
                }
            }
            .flatMap { channel in
                let promise = self.eventLoop.makePromise(of: Void.self)
                channel.close(promise: promise)
                return promise.futureResult
            }
    }
    
    deinit {
        do {
            try eventLoop.close()
        } catch {
            print(error)
        }
    }
}
