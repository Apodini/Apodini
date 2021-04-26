import OpenAPIKit
import Apodini

struct PallidorNamesCollisionChecker {
    private typealias OperationNames = [String]
    
    private var namesDictionary: [String: OperationNames] = [:]
    
    /// Registers operation name for the endpoint and asserts unique names
    mutating func register(operation: OpenAPI.Operation) {
        guard let operationName = operation.pallidorName, let endpointName = operation.pallidorEndpointName else { return }
        
        if namesDictionary[endpointName]?.contains(operationName) == true {
            fatalError("""
                    \(operationName) already registered under this subpath \(endpointName).
                    Pallidor operation names must be unique for methods of the same path.
                    """)
        }
        
        if namesDictionary[endpointName] == nil {
            namesDictionary[endpointName] = []
        }
        
        namesDictionary[endpointName]?.append(operationName)
    }
}

extension OpenAPI.Path {
    /// Pallidor endpoint name is set by dropping the version and retrieving the first component
    var pallidorEndpointName: String? {
        components.dropFirst().first
    }
}

extension OpenAPI.Operation {
    var pallidorName: String? {
        vendorExtensions[VendorExtensionKeys.pallidorOperationName]?.value as? String
    }
    
    var pallidorEndpointName: String? {
        vendorExtensions[VendorExtensionKeys.pallidorEndpointName]?.value as? String
    }
}
