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

public class HTTP2TestClient {
    public static let client: HTTP2TestClient = {
        do {
            return try .init()
        } catch {
            fatalError("dead")
        }
    }()
    
    let host = "localhost"
    let port = 443
    
    var numberOfErrors = 0
    var bootstrap: ClientBootstrap?
    var eventLoop: EventLoop
    var forwardChannelErrorToStreamsPromise: EventLoopPromise<Void>
    
    /// Adds a `SendRequestsHandler` to the passed `channel`, which will send the `requests`.
    /// `responseReceivedPromise` will be resolved when the response is received.
    private func send(
        requests: [TestHTTPRequest],
        on channel: Channel,
        with responseReceivedPromise: EventLoopPromise<[[HTTPClientResponsePart]]>
    ) -> EventLoopFuture<Void> {
        channel.eventLoop.assertInEventLoop()
        
        return channel.pipeline.addHandlers([HTTP2FramePayloadToHTTP1ClientCodec(httpProtocol: .https),
                                             SendRequestsHandler(host: self.host,
                                                                requests: requests,
                                                                responseReceivedPromise: responseReceivedPromise)],
                                            position: .last)
    }
    
    /// Send the `requests` on the `channel`
    /// Each array of requests is sent on its own stream.
    ///
    /// - parameters:
    ///   - channel: The root channel (ie. the actual TCP connection with the HTTP/2 multiplexer).
    ///   - requestGroups: The requests to send to the server, grouped into streams.
    ///   - channelErrorForwarder: A future that will be failed if we detect any errors on the parent channel (such as the
    ///                            server not speaking HTTP/2).
    ///  - returns: A future that will be fulfilled when the requests have been sent. The future holds a list of tuples.
    ///             Each tuple contains a request as well as the corresponding future that will hold the
    ///             `HTTPClientResponsePart`s of the received server response to that request.
    private func sendRequests(channel: Channel,
                      requestGroups: [[TestHTTPRequest]],
                      channelErrorForwarder: EventLoopFuture<Void>) -> EventLoopFuture<[([TestHTTPRequest], EventLoopPromise<[[HTTPClientResponsePart]]>)]> {
        // Step 1 is to find the HTTP2StreamMultiplexer so we can create HTTP/2 streams for our requests.
        return channel.pipeline.handler(type: HTTP2StreamMultiplexer.self).map { http2Multiplexer -> [([TestHTTPRequest], EventLoopPromise<[[HTTPClientResponsePart]]>)] in

            // Step 2: Let's create an HTTP/2 stream for each request.
            var responseReceivedPromises: [([TestHTTPRequest], EventLoopPromise<[[HTTPClientResponsePart]]>)] = []
            for requestGroup in requestGroups {
                let promise = channel.eventLoop.makePromise(of: [[HTTPClientResponsePart]].self)
                channelErrorForwarder.cascadeFailure(to: promise)
                responseReceivedPromises.append((requestGroup, promise))
                
                // Create the actual HTTP/2 stream using the multiplexer's `createStreamChannel` method.
                http2Multiplexer.createStreamChannel(promise: nil) { (channel: Channel) -> EventLoopFuture<Void> in
                    self.send(requests: requestGroup, on: channel, with: promise)
                }
            }
            return responseReceivedPromises
        }
    }
    
    private init() throws {
        var clientConfig = TLSConfiguration.makeClientConfiguration()
        clientConfig.applicationProtocols = ["h2"]
        clientConfig.certificateVerification = .none
        clientConfig.cipherSuites = "RSA+AESGCM"
        clientConfig.keyLogCallback = { buffer in
            let dir = FileManager.default.urls(for: FileManager.SearchPathDirectory.cachesDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).last!
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

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)

//        var dumpPCAP: String? = nil
//
//        // This will open a file to which we can dump the PCAPs if that's required.
//        let dumpPCAPFileSink = dumpPCAP.flatMap { (path: String) -> NIOWritePCAPHandler.SynchronizedFileSink? in
//            do {
//                return try NIOWritePCAPHandler.SynchronizedFileSink.fileSinkWritingToFile(path: path, errorHandler: {
//                    print("WRITE PCAP ERROR: \($0)")
//                })
//            } catch {
//                print("WRITE PCAP ERROR: \(error)")
//                return nil
//            }
//        }
//        defer {
//            try! dumpPCAPFileSink?.syncClose()
//        }
        
        self.numberOfErrors = 0

        self.eventLoop = group.next()

        // This promise will be fulfilled when the Channel closes (not very interesting) but more interestingly, it will
        // be fulfilled with an error if the heuristic has determined that the server probably doesn't speak HTTP/2.
        self.forwardChannelErrorToStreamsPromise = eventLoop.makePromise(of: Void.self)

        self.bootstrap = ClientBootstrap(group: eventLoop)
            .channelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .channelInitializer { channel in
                let heuristics = HeuristicForServerTooOldToSpeakGoodProtocolsHandler()
                let errorHandler = CollectErrorsAndCloseStreamHandler(promise: self.forwardChannelErrorToStreamsPromise)
                let sslHandler = try! NIOSSLClientHandler(context: sslContext, serverHostname: self.host)
                return channel.pipeline.addHandler(sslHandler).flatMap {
                    return channel.pipeline.addHandler(heuristics, position: .after(sslHandler))
                }.flatMap { _ in
//                    if let dumpPCAPFileSink = dumpPCAPFileSink {
//                        return channel.pipeline.addHandler(NIOWritePCAPHandler(mode: .client,
//                                                                               fakeRemoteAddress: try! .init(ipAddress: "1.2.3.4", port: 12345),
//                                                                               fileSink: dumpPCAPFileSink.write),
//                                                           position: .after(sslHandler))
//                    } else {
                    return channel.eventLoop.makeSucceededFuture(())
//                    }
                }.flatMap {
                    channel.pipeline.addHandler(errorHandler)
                }.flatMap {
                    channel.configureHTTP2Pipeline(mode: .client) { channel in
                        channel.eventLoop.makeSucceededVoidFuture()
                    }.map { (_: HTTP2StreamMultiplexer) in () }
                }
        }
    }
    
    public func sendTestRequests() {
        do {
            let requestGroups = [[
                TestHTTPRequest(target: "/", headers: [], body: nil, trailers: nil),
                TestHTTPRequest(target: "/moin", headers: [], body: nil, trailers: nil)
            ]]
            
            guard let bs = self.bootstrap else {
                return
            }
            
            let (channel, requestResponsePairs) = try bs.connect(host: host, port: port)
                .flatMap { channel in
                    self.sendRequests(channel: channel,
                                      requestGroups: requestGroups,
                                      channelErrorForwarder: self.forwardChannelErrorToStreamsPromise.futureResult).map {
                        (channel, $0)
                    }
                }
                .wait()

            // separate the already available targets (URIs) and the future received responses.
            //let requestGroups = requestResponsePairs.map { $0.0 }
            let responseFutures = requestResponsePairs.map { $0.1.futureResult }

            // Here, we build a future that aggregates all the responses from all the different requests.
            let allRequestsAndResponses = try EventLoopFuture<[[[HTTPClientResponsePart]]]>.reduce([],
                                                                                       responseFutures,
                                                                                       on: channel.eventLoop,
                                                                                       { $0 + [$1] })
                // zip the URIs and responses together again
                .map { zip(requestGroups, $0) }
                // and just wait until they arrive.
                .wait()
            
            for (requestGroup, responseGroup) in allRequestsAndResponses {
                print("Group: \(requestGroup.count) requests, \(responseGroup.count) responses")
//                if verbose {
//                    print("> GET \(uriAndResponse.0)")
//                }
//                for responsePart in uriAndResponse.1 {
//                    switch responsePart {
//                    case .head(let resHead):
//                        if verbose {
//                            print("< HTTP/\(resHead.version.major).\(resHead.version.minor) \(resHead.status.code)")
//                            for header in resHead.headers {
//                                print("< \(header.name): \(header.value)")
//                            }
//                        }
//                    case .body(let buffer):
//                        let written = buffer.withUnsafeReadableBytes { ptr in
//                            write(STDOUT_FILENO, ptr.baseAddress, ptr.count)
//                        }
//                        precondition(written == buffer.readableBytes) // technically, write could write short ;)
//                    case .end(_):
//                        if verbose {
//                            print("* Response fully received")
//                        }
//                    }
//                }
            }
        } catch {
            print("ERROR: \(error)")
            numberOfErrors += 1
            forwardChannelErrorToStreamsPromise.fail(error)
        }
    }
}
