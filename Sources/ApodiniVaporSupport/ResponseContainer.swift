//
//  ResponseContainer.swift
//  
//
//  Created by Tim Gymnich on 1.2.21.
//

import Foundation
import Apodini
import Vapor

public struct ResponseContainer: Encodable, ResponseEncodable {
    public typealias Links = [String: String]
    public var data: AnyEncodable?
    public var links: Links

    public enum CodingKeys: String, CodingKey {
        case data = "data"
        case links = "_links"
    }

    public init(links: [String: String]) {
        self.links = links
    }

    public init(_ data: AnyEncodable, links: [String: String]) {
        self.data = data
        self.links = links
    }

    public func encodeResponse(for request: Vapor.Request) -> EventLoopFuture<Vapor.Response> {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = [.withoutEscapingSlashes, .prettyPrinted]

        let response = Vapor.Response()
        do {
            try response.content.encode(self, using: jsonEncoder)
        } catch {
            return request.eventLoop.makeFailedFuture(error)
        }
        return request.eventLoop.makeSucceededFuture(response)
    }
}
