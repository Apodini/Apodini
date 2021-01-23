//
// Created by Andreas Bauer on 22.01.21.
//

@_implementationOnly import Vapor

struct ResponseContainer: Encodable, ResponseEncodable {
    typealias Links = [String: String]
    var data: AnyEncodable?
    var links: Links

    enum CodingKeys: String, CodingKey {
        case data = "data"
        case links = "_links"
    }

    init(links: [String: String]) {
        self.links = links
    }

    init(_ data: AnyEncodable, links: [String: String]) {
        self.data = data
        self.links = links
    }

    func encodeResponse(for request: Vapor.Request) -> EventLoopFuture<Vapor.Response> {
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
