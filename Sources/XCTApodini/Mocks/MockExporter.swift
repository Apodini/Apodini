//
//  MockExporter.swift
//  
//
//  Created by Paul Schmiedmayer on 3/8/21.
//

#if DEBUG
@testable import Apodini


open class MockExporter: InterfaceExporter {
    public var endpoints: [AnyEndpoint] = []
    
    
    public required init(_ app: Apodini.Application) {}

    
    public func export<H: Handler>(_ endpoint: Endpoint<H>) {
        self.endpoints.append(endpoint)
    }
    
    public func retrieveParameter<Type: Decodable>(_ parameter: EndpointParameter<Type>, for request: MockExporterRequest) throws -> Type?? {
        for mockableParameter in request.mockableParameters.values {
            let value = mockableParameter.getValue(for: parameter)
            if value != nil {
                return value
            }
        }
        return nil
    }
    
    open func finishedExporting(_ webService: WebServiceModel) {}
}


extension MockExporter: StandardErrorCompliantExporter {
    public typealias ErrorMessagePrefixStrategy = StandardErrorMessagePrefix
}
#endif
