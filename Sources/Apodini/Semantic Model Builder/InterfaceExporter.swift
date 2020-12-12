//
// Created by Andi on 22.11.20.
//

import Vapor

protocol InterfaceExporter: RequestInjectableDecoder {
    init(_ app: Application)

    func export(_ endpoint: Endpoint)

    func finishedExporting(_ root: EndpointsTreeNode)

    func decode<T: Decodable>(_ type: T.Type, from request: Vapor.Request) throws -> T?
}

extension InterfaceExporter {
    func finishedExporting(_ root: EndpointsTreeNode) {}
}
