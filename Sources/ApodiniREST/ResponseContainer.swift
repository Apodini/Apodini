//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Apodini
import ApodiniUtils
import ApodiniNetworking
import Foundation


public struct ResponseContainer: Encodable {
    public typealias Links = [String: String]
    
    public enum CodingKeys: String, CodingKey {
        case data = "data"
        case links = "_links"
    }
    
    
    let status: Status?
    let information: InformationSet
    let data: AnyEncodable?
    let links: Links?
    let encoder: AnyEncoder
    
    var containsNoContent: Bool {
        data == nil && (links?.isEmpty ?? true)
    }
    
    init<E: Encodable>(
        _ type: E.Type = E.self,
        status: Status? = nil,
        information: InformationSet = [],
        data: E? = nil,
        links: Links? = nil,
        encoder: AnyEncoder = JSONEncoder()
    ) {
        self.status = status
        self.information = information
        self.encoder = encoder
        
        if let data = data {
            self.data = AnyEncodable(data)
        } else {
            self.data = nil
        }
        
        // We do not want to add a response body in case there are no links.
        // Therefore we set `links` to nil so it is ignored in the encoding process.
        if let links = links, !links.isEmpty {
            self.links = links
        } else {
            self.links = nil
        }
    }
    
    
    public func encodeResponse(for request: HTTPRequest) -> EventLoopFuture<HTTPResponse> {
        let response = HTTPResponse(
            version: request.version,
            status: .ok,
            headers: HTTPHeaders(information)
        )
        
        switch status {
        case .noContent where !containsNoContent:
            // If there is any content in the HTTP body (data or links) we must not return an status code .noContent
            response.status = .ok
        case let .some(status):
            response.status = .init(status)
        default:
            response.status = containsNoContent ? .noContent : .ok
        }
        
        do {
            if !containsNoContent {
                var buffer = ByteBuffer()
                try self.encoder.encode(self, to: &buffer, headers: &response.headers)
                response.bodyStorage = .buffer(buffer)
            }
        } catch {
            return request.eventLoop.makeFailedFuture(error)
        }
        return request.eventLoop.makeSucceededFuture(response)
    }
}
