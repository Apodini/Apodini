//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2018 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIO
import NIOHTTP1
import NIOHTTP2
import NIOTLS
import NIOSSL
import Foundation
import NIOExtras

var clientConfig = TLSConfiguration.makeClientConfiguration()
clientConfig.applicationProtocols = ["h2"]
let sslContext = try NIOSSLContext(configuration: clientConfig)

let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
defer {
    try! group.syncShutdownGracefully()
}

var verbose = false
var dumpPCAP: String? = nil
var args = CommandLine.arguments.dropFirst()

let urls = args.compactMap(URL.init(string:))
guard urls.count > 0 else {
    usage()
    exit(1)
}

/// This will build a map from distinct host/port tuples to the full URLs to send to this host.
///
/// For example if we receive the following three URLs:
///  - `https://foo.com/bar`
///  - `https://foo.com/buz`
///  - `https://example.net/example`
///
/// hostsToURLsMap will contain two entries: One for `foo.com` (containing two URLs) and one for `example.net`
/// (containing one URL).
let hostToURLsMap: [HostAndPort: [URL]] = Dictionary(grouping:
    urls.map { url -> (host: String, port: Int, url: URL) in
        guard let host = url.host else {
            print("ERROR: URL '\(url)' does not have a hostname which is required")
            exit(1)
        }
        guard url.scheme == "https" else {
            print("ERROR: URL '\(url)' is not https but that's required")
            exit(1)
        }
        return (host, url.port ?? 443, url)
    }
    , by: { HostAndPort(host: $0.host, port: $0.port) }).mapValues { $0.map { $0.url }}

if verbose {
    print("* will create the following \(hostToURLsMap.count) HTTP/2 connections")
    for hostAndURL in hostToURLsMap {
        print("* - connection to https://\(hostAndURL.0.host):\(hostAndURL.0.port)")
        for url in hostAndURL.1 {
            print("*   * stream for \(url.path != "" ? url.path : "/")")
        }
    }
}

// This will open a file to which we can dump the PCAPs if that's required.
let dumpPCAPFileSink = dumpPCAP.flatMap { (path: String) -> NIOWritePCAPHandler.SynchronizedFileSink? in
    do {
        return try NIOWritePCAPHandler.SynchronizedFileSink.fileSinkWritingToFile(path: path, errorHandler: {
            print("WRITE PCAP ERROR: \($0)")
        })
    } catch {
        print("WRITE PCAP ERROR: \(error)")
        return nil
    }
}
defer {
    try! dumpPCAPFileSink?.syncClose()
}

/// Make requests for the URIs `uri`s using a new HTTP/2 stream on `channel`.
///
/// - parameters:
///   - channel: The root channel (ie. the actual TCP connection with the HTTP/2 multiplexer).
///   - host: The host the request is for (for the `host:` header).
///   - uris: The URIs to request from the server.
///   - channelErrorForwarder: A future that will be failed if we detect any errors on the parent channel (such as the
///                            server not speaking HTTP/2).
///  - returns: A future that will be fulfilled when the requests have been sent. The future holds a list of tuples.
///             Each tuple contains the `uri` of a request as well as the corresponding future that will hold the
///             `HTTPClientResponsePart`s of the received server response to that request.
func makeRequests(channel: Channel,
                  host: String,
                  uris: [String],
                  channelErrorForwarder: EventLoopFuture<Void>) -> EventLoopFuture<[(String, EventLoopPromise<[HTTPClientResponsePart]>)]> {
    // Step 1 is to find the HTTP2StreamMultiplexer so we can create HTTP/2 streams for our requests.
    return channel.pipeline.handler(type: HTTP2StreamMultiplexer.self).map { http2Multiplexer -> [(String, EventLoopPromise<[HTTPClientResponsePart]>)] in
        var remainingURIs = uris
        // Helper function to initialise an HTTP/2 stream.
        func requestStreamInitializer(uri: String,
                                      responseReceivedPromise: EventLoopPromise<[HTTPClientResponsePart]>,
                                      channel: Channel) -> EventLoopFuture<Void> {
            let uri = remainingURIs.removeFirst()
            channel.eventLoop.assertInEventLoop()
            return channel.pipeline.addHandlers([HTTP2FramePayloadToHTTP1ClientCodec(httpProtocol: .https),
                                                 SendRequestHandler(host: host,
                                                                    request: .init(target: uri,
                                                                                   headers: [],
                                                                                   body: nil,
                                                                                   trailers: nil),
                                                                    responseReceivedPromise: responseReceivedPromise)],
                                                position: .last)
        }

        // Step 2: Let's create an HTTP/2 stream for each request.
        var responseReceivedPromises: [(String, EventLoopPromise<[HTTPClientResponsePart]>)] = []
        for uri in uris {
            let promise = channel.eventLoop.makePromise(of: [HTTPClientResponsePart].self)
            channelErrorForwarder.cascadeFailure(to: promise)
            responseReceivedPromises.append((uri, promise))
            // Create the actual HTTP/2 stream using the multiplexer's `createStreamChannel` method.
            http2Multiplexer.createStreamChannel(promise: nil) { (channel: Channel) -> EventLoopFuture<Void> in
                // Call the above handler to initialise the stream which will send off the actual request.
                requestStreamInitializer(uri: uri,
                                         responseReceivedPromise: promise,
                                         channel: channel)
            }
        }
        return responseReceivedPromises
    }
}

var numberOfErrors = 0
// Here we just loop over all the hosts we send requests to. The hosts will be contacted sequentially but if there are
// multiple requests for one host, those will be queried concurrently in one TCP connection.
for hostAndURL in hostToURLsMap {
    let uris = hostAndURL.value.map { url in url.absoluteURL.path == "" ? "/" : url.absoluteURL.path }
    let host = hostAndURL.key.host
    let port = hostAndURL.key.port
    if verbose {
        print("* Querying \(host) for \(uris)")
    }

    let eventLoop = group.next()

    // This promise will be fulfilled when the Channel closes (not very interesting) but more interestingly, it will
    // be fulfilled with an error if the heuristic has determined that the server probably doesn't speak HTTP/2.
    let forwardChannelErrorToStreamsPromise = eventLoop.makePromise(of: Void.self)

    let bootstrap = ClientBootstrap(group: eventLoop)
        .channelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
        .channelInitializer { channel in
            let heuristics = HeuristicForServerTooOldToSpeakGoodProtocolsHandler()
            let errorHandler = CollectErrorsAndCloseStreamHandler(promise: forwardChannelErrorToStreamsPromise)
            let sslHandler = try! NIOSSLClientHandler(context: sslContext, serverHostname: host)
            return channel.pipeline.addHandler(sslHandler).flatMap {
                return channel.pipeline.addHandler(heuristics, position: .after(sslHandler))
            }.flatMap { _ in
                if let dumpPCAPFileSink = dumpPCAPFileSink {
                    return channel.pipeline.addHandler(NIOWritePCAPHandler(mode: .client,
                                                                           fakeRemoteAddress: try! .init(ipAddress: "1.2.3.4", port: 12345),
                                                                           fileSink: dumpPCAPFileSink.write),
                                                       position: .after(sslHandler))
                } else {
                    return channel.eventLoop.makeSucceededFuture(())
                }
            }.flatMap {
                channel.pipeline.addHandler(errorHandler)
            }.flatMap {
                channel.configureHTTP2Pipeline(mode: .client) { channel in
                    channel.eventLoop.makeSucceededVoidFuture()
                }.map { (_: HTTP2StreamMultiplexer) in () }
            }
    }

    do {
        let (channel, uriResponsePairs) = try bootstrap.connect(host: host, port: port)
            .flatMap { channel in
                makeRequests(channel: channel,
                             host: host,
                             uris: uris,
                             channelErrorForwarder: forwardChannelErrorToStreamsPromise.futureResult).map {
                                (channel, $0)
                }
            }
            .wait()
        if verbose {
            print("* Connected to \(host) (\(channel.remoteAddress!))")
        }

        // separate the already available targets (URIs) and the future received responses.
        let targets = uriResponsePairs.map { $0.0 }
        let responseFutures = uriResponsePairs.map { $0.1.futureResult }

        // Here, we build a future that aggregates all the responses from all the different requests.
        let allURIsAndResponses = try EventLoopFuture<[[HTTPClientResponsePart]]>.reduce([],
                                                                                   responseFutures,
                                                                                   on: channel.eventLoop,
                                                                                   { $0 + [$1] })
            // zip the URIs and responses together again
            .map { zip(targets, $0) }
            // and just wait until they arrive.
            .wait()
        for uriAndResponse in allURIsAndResponses {
            if verbose {
                print("> GET \(uriAndResponse.0)")
            }
            for responsePart in uriAndResponse.1 {
                switch responsePart {
                case .head(let resHead):
                    if verbose {
                        print("< HTTP/\(resHead.version.major).\(resHead.version.minor) \(resHead.status.code)")
                        for header in resHead.headers {
                            print("< \(header.name): \(header.value)")
                        }
                    }
                case .body(let buffer):
                    let written = buffer.withUnsafeReadableBytes { ptr in
                        write(STDOUT_FILENO, ptr.baseAddress, ptr.count)
                    }
                    precondition(written == buffer.readableBytes) // technically, write could write short ;)
                case .end(_):
                    if verbose {
                        print("* Response fully received")
                    }
                }
            }
        }
    } catch {
        print("ERROR: \(error)")
        numberOfErrors += 1
        forwardChannelErrorToStreamsPromise.fail(error)
    }
}
exit(numberOfErrors == 0 ? EXIT_SUCCESS : EXIT_FAILURE)
