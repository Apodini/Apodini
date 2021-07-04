//
// Created by Andreas Bauer on 22.01.21.
//

import Apodini
import ApodiniUtils
import Vapor


public struct ResponseContainer: Encodable, ResponseEncodable {
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
    
    init<E: Encodable>(_ type: E.Type = E.self,
                       status: Status? = nil,
                       information: InformationSet = [],
                       data: E? = nil,
                       links: Links? = nil,
                       encoder: AnyEncoder = JSONEncoder()) {
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
    
    
    public func encodeResponse(for request: Vapor.Request) -> EventLoopFuture<Vapor.Response> {
        let response = Vapor.Response()
        response.headers = HTTPHeaders(information)
        
        switch status {
        case .noContent where !containsNoContent:
            // If there is any content in the HTTP body (data or links) we must not return an status code .noContent
            response.status = .ok
        case let .some(status):
            response.status = HTTPStatus(status)
        default:
            if containsNoContent {
                response.status = .noContent
            } else {
                response.status = .ok
            }
        }
        
        do {
            if !containsNoContent {
                try response.content.encode(self, using: self.encoder)
            }
        } catch {
            return request.eventLoop.makeFailedFuture(error)
        }
        return request.eventLoop.makeSucceededFuture(response)
    }
}
