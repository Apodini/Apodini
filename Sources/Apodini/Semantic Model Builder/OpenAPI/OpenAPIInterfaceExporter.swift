//
//  Created by Paul Schmiedmayer on 11/3/20.
//

@_implementationOnly import OpenAPIKit
@_implementationOnly import Vapor
import Foundation

class OpenAPIInterfaceExporter: InterfaceExporter {
    typealias ExporterRequest = Vapor.Request


    let app: Application
    var documentBuilder: OpenAPIDocumentBuilder
    let configuration: OpenAPIConfiguration

    required init(_ app: Application) {
        self.app = app
        self.configuration = OpenAPIConfiguration.create(from: app)
        self.documentBuilder = OpenAPIDocumentBuilder(
                configuration: configuration
        )
    }

    func export<H: Handler>(_ endpoint: Endpoint<H>) {
        documentBuilder.addEndpoint(endpoint)
    }

    func finishedExporting(_ webService: WebServiceModel) {
        serveSpecification()
    }

    private func serveSpecification() {
        // swiftlint:disable:next todo
        // TODO: add YAML and default case?
        // swiftlint:disable:next todo
        // TODO: add file export?
        if let outputRoute = configuration.outputEndpoint {
            switch configuration.outputFormat {
            case .JSON:
                app.get(outputRoute.pathComponents) { (_: Vapor.Request) in
                    self.documentBuilder.description
                }
            case .YAML:
                print("Not implemented yet.")
            default:
                print("Not implemented yet.")
            }
        }
    }

    func retrieveParameter<Type: Decodable>(_ parameter: EndpointParameter<Type>, for request: Vapor.Request) throws -> Type?? {
        switch parameter.parameterType {
        case .lightweight:
            // Note: Vapor also supports decoding into a struct which holds all query parameters. Though we have the requirement,
            //   that .lightweight parameter types conform to LosslessStringConvertible, meaning our DSL doesn't allow for that right now

            guard let query = request.query[Type.self, at: parameter.name] else {
                return nil // the query parameter doesn't exists
            }
            return query
        case .path:
            guard let stringParameter = request.parameters.get(parameter.pathId) else {
                return nil // the path parameter didn't exist on that request
            }
            guard let losslessStringParameter = parameter as? LosslessStringConvertibleEndpointParameter else {
                #warning("Must be replaced with a proper error to encode a response to the user")
                fatalError("Encountered .path Parameter which isn't type of LosslessStringConvertible!")
            }

            guard let value = losslessStringParameter.initFromDescription(description: stringParameter, type: Type.self) else {
                #warning("Must be replaced with a proper error to encode a response to the user")
                fatalError("""
                           Parsed a .path Parameter, but encountered invalid format when initializing LosslessStringConvertible!
                           Could not init \(Type.self) for string value '\(stringParameter)'
                           """)
            }
            return value
        case .content:
            guard request.body.data != nil else {
                // If the request doesn't have a body, there is nothing to decide.
                return nil
            }

            #warning("""
                     A Handler could define multiple .content Parameters. In such a case the REST exporter would
                     need to decode the content via a struct containing those .content parameters as properties.
                     This is currently unsupported.
                     """)

            return try request.content.decode(Type.self, using: JSONDecoder())
        }
    }
}
