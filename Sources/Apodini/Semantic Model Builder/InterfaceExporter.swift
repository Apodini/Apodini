//
// Created by Andi on 22.11.20.
//

@_implementationOnly import Vapor

protocol InterfaceExporter {
    init(_ app: Application)

    func export(_ node: EndpointsTreeNode)
}
