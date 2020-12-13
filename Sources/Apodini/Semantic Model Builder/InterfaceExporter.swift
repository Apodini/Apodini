//
// Created by Andi on 22.11.20.
//

import Vapor

protocol InterfaceExporter: RequestInjectableDecoder, ResponseEncoder {
    init(_ app: Application)

    func export(_ endpoint: Endpoint)

    func finishedExporting(_ webService: WebServiceModel)

    func decode<T: Decodable>(_ type: T.Type, from request: Vapor.Request) throws -> T?

    func encode<T: Encodable>(_ value: T, request: Vapor.Request) throws -> EventLoopFuture<Vapor.Response>
}

extension InterfaceExporter {
    func finishedExporting(_ webService: WebServiceModel) {}
}
