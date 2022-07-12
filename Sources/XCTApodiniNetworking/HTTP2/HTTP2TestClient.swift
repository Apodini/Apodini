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

struct AddStruct: Codable {
    let sum: Int
    let number: Int
}

final class AddingStreamingDelegate: StreamingDelegate {
    typealias SRequest = DATAFrameRequest<AddStruct>
    typealias SResponse = AddStruct
    var streamingHandler: HTTPClientStreamingHandler<AddingStreamingDelegate>?
    var headerFields: BasicHTTPHeaderFields
    
    var responseCount = 0
    
    func handleInbound(response: AddStruct, serverSideClosed: Bool) {
        if responseCount == 1 {
            close()
            return
        }
        
        responseCount += 1
        
        let newNumber = Int.random(in: 0..<10)
        let addStruct = AddStruct(sum: response.sum + response.number, number: newNumber)
        
        sendOutbound(request: DATAFrameRequest(query: addStruct))
    }
    
    func handleStreamStart() {
        let addStruct = AddStruct(sum: 0, number: 4)
        
        sendOutbound(request: DATAFrameRequest(query: addStruct))
    }
    
    init(_ headerfields: BasicHTTPHeaderFields) {
        self.headerFields = headerfields
    }
}

public class HTTP2TestClient {
    // MARK: Singleton pattern
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
    var forwardChannelErrorToStreamsPromise: EventLoopPromise<Void>
    
    private init() throws {
        // MARK: Client Config, mainly about TLS
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
        
        // MARK: Set up the connection bootstrap
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)

        self.eventLoop = group.next()

        // This promise will be fulfilled when the Channel closes (not very interesting) but more interestingly, it will
        // be fulfilled with an error if the heuristic has determined that the server probably doesn't speak HTTP/2.
        self.forwardChannelErrorToStreamsPromise = eventLoop.makePromise(of: Void.self)

        self.bootstrap = ClientBootstrap(group: eventLoop)
            .channelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .channelInitializer { channel in
                //let heuristics = HeuristicForServerTooOldToSpeakGoodProtocolsHandler()
                let errorHandler = CollectErrorsAndCloseStreamHandler(promise: self.forwardChannelErrorToStreamsPromise)
                let sslHandler = try! NIOSSLClientHandler(context: sslContext, serverHostname: HTTP2TestClient.host)
                return channel.pipeline.addHandler(sslHandler).flatMap {
                    channel.pipeline.addHandler(errorHandler)
                }.flatMap {
                    channel.configureHTTP2Pipeline(mode: .client) { channel in
                        channel.eventLoop.makeSucceededVoidFuture()
                    }.map { (_: HTTP2StreamMultiplexer) in () }
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
    
    public func sendTestRequests() {
        // Set the header fields
        let headerFields = BasicHTTPHeaderFields(method: .POST, url: "/http/add", host: "localhost")
        
        // Create the StreamingDelegate
        let delegate = AddingStreamingDelegate(headerFields)
        
        guard let bs = self.bootstrap else {
            return
        }
        
        do {
            _ = try bs.connect(host: "localhost", port: 443)
                .flatMap { channel in
                    self.registerStreamingHandler(channel: channel, streamingDelegate: delegate)
                        .and(value: channel)
                }
                .flatMap { streamChannel, channel in
                    streamChannel.closeFuture.and(value: channel)
                }
                .map { void, channel in
                    channel.close()
                }
                .wait()
            
//            try streamChannel.closeFuture.flatMap {
//                channel
//            }
//            .map { actualChannel in
//                actualChannel.close()
//            }
//            .wait()

//            // separate the already available targets (URIs) and the future received responses.
//            //let requestGroups = requestResponsePairs.map { $0.0 }
//            let responseFutures = requestResponsePairs.map { $0.1.futureResult }
//
//            // Here, we build a future that aggregates all the responses from all the different requests.
//            let allRequestsAndResponses = try EventLoopFuture<[[[HTTP2Frame.FramePayload]]]>.reduce([],
//                                                                                       responseFutures,
//                                                                                       on: channel.eventLoop,
//                                                                                       { $0 + [$1] })
//                // zip the URIs and responses together again
//                .map { zip(requestGroups, $0) }
//                // and just wait until they arrive.
//                .wait()
//
//            for (requestGroup, responseGroup) in allRequestsAndResponses {
//                let actualResponseGroup = responseGroup[0]
//                print("Group: \(requestGroup.requests.count) requests, \(actualResponseGroup.count) responses")
//
//                for response in actualResponseGroup {
//                    if case .data(let dataPayload) = response,
//                       case .byteBuffer(let buffer) = dataPayload.data {
//                        if buffer.readableBytes == 0 && dataPayload.endStream {
//                            print("Empty DATA frame to end stream")
//                        }
//                        print(buffer.getString(at: 0, length: buffer.readableBytes) ?? "Can't convert")
//                    } else if case .headers = response {
//                        print("HEADERS frame")
//                    }
//                }
//            }
        } catch {
            print("ERROR: \(error)")
            numberOfErrors += 1
            forwardChannelErrorToStreamsPromise.fail(error)
        }
    }
}
