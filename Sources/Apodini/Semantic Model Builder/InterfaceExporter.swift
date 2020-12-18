//
// Created by Andi on 22.11.20.
//

import Vapor

protocol InterfaceExporter {
    init(_ app: Application)

    func export(_ endpoint: Endpoint)

    func finishedExporting(_ webService: WebServiceModel)
}

extension InterfaceExporter {
    func finishedExporting(_ webService: WebServiceModel) {}
}
