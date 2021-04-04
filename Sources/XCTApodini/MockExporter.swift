//
// Created by Andreas Bauer on 25.12.20.
//

//#if DEBUG
//import Foundation
//import class Vapor.Application
//import class Vapor.Request
//@testable import Apodini
//
//
////extension String: ExporterRequest {}
//
//open class _MockExporter: InterfaceExporter {
//    public var endpoints: [AnyEndpoint] = []
//
//    public required init(_ app: Apodini.Application) {}
//
//    public func export<H: Handler>(_ endpoint: Endpoint<H>) {
//        self.endpoints.append(endpoint)
//    }
//
//    public func retrieveParameter<Type: Decodable>(_ parameter: EndpointParameter<Type>, for request: MockExporterRequest) throws -> Type?? {
//        for mockableParameter in request.mockableParameters.values {
//            let value = mockableParameter.getValue(for: parameter)
//            if value != nil {
//                return value
//            }
//        }
//        return nil
//    }
//
//    open func finishedExporting(_ webService: WebServiceModel) {}
//}
//
//extension _MockExporter: StandardErrorCompliantExporter {
//    public typealias ErrorMessagePrefixStrategy = StandardErrorMessagePrefix
//}
////
/////// You can use the MockExporter to foll a Handler with predefined queued number of parameters
/////// The order of the injection of the parameter values must be deterministic in order for the MockExporter to work.
/////// You can specify parameters in the following from:
/////// - Value: Just pass the value to the respective function or initializer. Reflects a request that contains a specific value for the next `@Parameter`.
/////// - `.nil`: Explcitly pass in a nil value that is injected into the handler's respective `@Parameter`. Reflects a request with an explcit nil value (e.g. null in JSON)  in the request for the next `@Parameter`.
/////// - `.none`: Skip this value in the injection. Reflects a request with no value for the next `@Parameter`.
////open class OldMockExporter<Request: ExporterRequest>: InterfaceExporter {
////    var parameterValues: [Any??] = []
////
////    /// Creates a new MockExporter which uses the passed parameter values as FIFO queue on retrieveParameter
////    public required init(queued parameterValues: Any??...) {
////        self.parameterValues = parameterValues
////    }
////
////    // See https://bugs.swift.org/browse/SR-128
////    public required init(queuedParameterValues parameterValues: [Any??]) {
////        self.parameterValues = parameterValues
////    }
////
////    public required init(_ app: Apodini.Application) {}
////
////    open func export<H: Handler>(_ endpoint: Endpoint<H>) {
////        // do nothing
////    }
////
////    open func finishedExporting(_ webService: WebServiceModel) {
////        // do nothing
////    }
////
////    public func append(injected: Any??...) {
////        append(injected: injected)
////    }
////
////    public func append(injected: [Any??]) {
////        parameterValues.append(contentsOf: injected)
////    }
////
////    public func retrieveParameter<Type: Decodable>(_ parameter: EndpointParameter<Type>, for request: Request) throws -> Type?? {
////        guard let first = parameterValues.first else {
////        //guard !parameterValues.isEmpty else {
////            print("WARN: MockExporter failed to retrieve next parameter for '\(parameter.description)'. Queue is empty")
////            return nil // non existence
////        }
////
////        guard let value = first else {
////        //guard let value = parameterValues.removeFirst() else {
////            return nil // non existence
////        }
////        guard let unwrapped = value else {
////            return .null // explicit nil
////        }
////
////        guard let casted = unwrapped as? Type else {
////            XCTFail("MockExporter: Could not cast value \(String(describing: value)) to type \(Type?.self) for '\(parameter.description)'")
////            return nil
////            //fatalError("MockExporter: Could not cast value \(String(describing: value)) to type \(Type?.self) for '\(parameter.description)'")
////        }
////        return casted
////    }
////}
//#endif
