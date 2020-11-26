//
//  Body.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import Vapor
import Foundation


/// The `@Parameter` property wrapper can be used to express input in different ways:
/// * **Request Content**: Parameters can be part of the requests send to the web service such as the HTTP body or request content of an other protocol.
/// * **Lightweight Parameter**: Some middleware types and protocols can expose parameters as lightweight parameters that can be part of a URI path such as query parameterst found in the URI of RESTful and OpenAPI based web APIs.
/// * **Path Parameters**: Parameters can also be used to define the endpoint such as the URI path of the middleware types and protocols that support URI based multiplexing of requests.
@propertyWrapper
public struct Parameter<Element: Codable> {
    /// The `ParameterType` allows a developer to explicitly describe the type of parameter that should be used for the wrapped property
    public enum ParameterType {
        /// The `.automatic` `ParameterType` allows Apodini to select the most suiting `ParameterType` based on the wrapped property, the `Component` and other context.
        case automatic
        /// The `Parameter` is exposed as a request content. Parameters can be part of the requests send to the web service such as the HTTP body or request content of an other protocol.
        case content
        /// The `Parameter` is exposed as a lightweight parameter. Some middleware types and protocols can expose parameters as lightweight parameters that can be part of a URI path such as query parameterst found in the URI of RESTful and OpenAPI based web APIs.
        case lightweight
        /// The `Parameter` is exposed as a an identifying parameter. Identifying parameters can be used to define a parameter e.g. in an URI path of the middleware types and protocols that support adding parameters as part of the URI path of a request.
        case identifier
    }
    
    struct PathParameterID<Element> {
        let id: UUID
    }
    
    private var element: Element?
    private var name: String?
    private var parameterType: ParameterType = .automatic
    private var id = UUID()
    
    
    /// The value for the `@Parameter` as defined by the incoming request
    public var wrappedValue: Element {
        guard let element = element else {
            fatalError("You can only access the body while you handle a request")
        }
        
        return element
    }
    
    /// The `projectedValue` can be accessed using a `$` prefix before the property wrapped using the  `@Parameter` property wrapper.
    /// It  can be used to pass a `.path` Parameter to children components.
    ///
    /// Example:
    /// The `@Parameter` property used as a path parameter can also be defined outside the component as part of a Group that contains the `Compoent`.
    /// ```swift
    /// struct Bird: Identifiable {
    ///     var id: Int
    ///     var name: String
    ///     var age: Int
    /// }
    ///
    /// struct ExampleBirdComponent: Component {
    ///     // As this was passed in from the outside this is automatically used as a path parameter
    ///     @Parameter var birdID: Bird.ID
    ///
    ///     // ...
    /// }
    ///
    /// struct ExampleNestComponent: Component {
    ///     // As this was passed in from the outside this is automatically used as a path param
    ///     @Parameter var birdID: Bird.ID
    ///     // Exposed as a lightweight parameter
    ///     @Parameter var nestName: String?
    ///
    ///     // ...
    /// }
    ///
    /// struct TestWebService: WebService {
    ///     @Parameter var birdID: Bird.ID
    ///
    ///     var content: some Component {
    ///         Group("api", "birds", birdID) {
    ///             ExampleBirdComponent(birdID: $birdID)
    ///             Group("nests") {
    ///                 ExampleNestComponent(birdID: $birdID)
    ///             }
    ///         }
    ///     }
    /// }
    ///
    /// TestWebService.main()
    /// ```
    public var projectedValue: Parameter {
        guard parameterType == .identifier || parameterType == .automatic else {
            preconditionFailure("Only `.path` or `.automatic` parameters are allowed to be passed to a `Component`.")
        }
        
        return Parameter(name: self.name, parameterType: .identifier, id: self.id)
    }
    
    /// - Parameter parameterType: The `ParameterType` that explicitly describes the type of parameter that should be used for the wrapped property
    public init(_ parameterType: ParameterType = .automatic) {
        self.parameterType = parameterType
    }
    
    /// - Parameters:
    ///   - name: The name used to describe the wrapped property for in the web APIs
    ///   - parameterType: The `ParameterType` that explicitly describes the type of parameter that should be used for the wrapped property
    public init(_ name: String, _ parameterType: ParameterType = .automatic) {
        self.name = name
        self.parameterType = parameterType
    }
    
    private init(_ pathParameterID: PathParameterID<Element>) {
        self.parameterType = .identifier
        self.id = pathParameterID.id
    }
    
    private init(name: String?, parameterType: ParameterType, id: UUID) {
        self.name = name
        self.parameterType = parameterType
        self.id = id
    }
}

extension Parameter: RequestInjectable {
    mutating func inject(using request: Vapor.Request, with decoder: SemanticModelBuilder?) throws {
        if let decoder = decoder {
            element = try decoder.decode(Element.self, from: request)
        }
    }
}
