//
// Created by Andreas Bauer on 03.07.21.
//

import Vapor
import Apodini

public struct ErrorResponse: Encodable, ResponseEncodable {
    let apodiniError: ApodiniError
    let encoder: AnyEncoder

    let error = true
    let reason: String

    public enum CodingKeys: String, CodingKey {
        case error
        case reason
    }

    init(_ error: Error, encoder: AnyEncoder = JSONEncoder()) {
        self.apodiniError = error.apodiniError
        self.reason = apodiniError.message(for: RESTInterfaceExporter.self)
        self.encoder = encoder
    }

    public func encodeResponse(for request: Vapor.Request) -> EventLoopFuture<Vapor.Response> {
        let response = Vapor.Response()
        response.headers = HTTPHeaders(apodiniError.information)

        response.status = HTTPStatus(apodiniError.option(for: .errorType))

        do {
            try response.content.encode(self, using: encoder)
        } catch {
            return request.eventLoop.makeFailedFuture(error)
        }
        
        return request.eventLoop.makeSucceededFuture(response)
    }
}
