//
// Created by Andreas Bauer on 22.01.21.
//

import Apodini
import ApodiniUtils
import Vapor

struct ResponseContainer: Encodable, ResponseEncodable {
    typealias Links = [String: String]
    
    enum CodingKeys: String, CodingKey {
        case data = "data"
        case links = "_links"
    }
    
    
    let status: Status?
    let data: AnyEncodable?
    let links: Links?
    
    var containsNoContent: Bool {
        data == nil && (links?.isEmpty ?? true)
    }
    
    init<E: Encodable>(_ type: E.Type = E.self, status: Status? = nil, data: E? = nil, links: Links? = nil) {
        self.status = status
        
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
    
    
    func encodeResponse(for request: Vapor.Request) -> EventLoopFuture<Vapor.Response> {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = [.withoutEscapingSlashes, .prettyPrinted]

        let response = Vapor.Response()
        
        switch status {
        case .noContent where !containsNoContent:
            // If there is any content in the HTTP body (data or links) we must not return an status code .noContent
            response.status = .ok
        case let .some(status):
            response.status = httpStatusCode(fromStatus: status)
        default:
            if containsNoContent {
                response.status = .noContent
            } else {
                response.status = .ok
            }
        }
        
        do {
            if !containsNoContent {
                try response.content.encode(self, using: jsonEncoder)
            }
        } catch {
            return request.eventLoop.makeFailedFuture(error)
        }
        return request.eventLoop.makeSucceededFuture(response)
    }
    
    private func httpStatusCode(fromStatus status: Status) -> HTTPStatus {
        switch status {
        case .ok:
            return HTTPStatus.ok
        case .created:
            return HTTPStatus.created
        case .noContent:
            return HTTPStatus.noContent
        }
    }
}
