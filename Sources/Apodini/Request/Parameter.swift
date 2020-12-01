//
//  Body.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import Vapor
import Foundation

/* Generic Parameter that can be used to mark that the options are meant for @Parameter */
public enum ParameterOptionNameSpace { }

/// The `@Parameter` property wrapper can be used to express input in different ways:
/// * **Request Content**: Parameters can be part of the requests send to the web service such as the HTTP body or request content of an other protocol.
/// * **Lightweight Parameter**: Some middleware types and protocols can expose parameters as lightweight parameters that can be part of a URI path such as query parameters found in the URI of RESTful and OpenAPI based web APIs.
/// * **Path Parameters**: Parameters can also be used to define the endpoint such as the URI path of the middleware types and protocols that support URI based multiplexing of requests.
@propertyWrapper
public struct Parameter<Element: Codable> {
    public typealias OptionKey<T: PropertyOption> = PropertyOptionKey<ParameterOptionNameSpace, T>
    public typealias Option = AnyPropertyOption<ParameterOptionNameSpace>

    private var element: Element?
    private var name: String?
    private var options: PropertyOptionSet<ParameterOptionNameSpace>
    private var id = UUID()
    private var defaultValue: Element?
    
    /// The value for the `@Parameter` as defined by the incoming request
    public var wrappedValue: Element {
        guard let element = element else {
            fatalError("You can only access the body while you handle a request")
        }
        
        return element
    }
    
    /// The `projectedValue` can be accessed using a `$` prefix before the property wrapped using the  `@Parameter` property wrapper.
    /// It  can be used to pass a `.identifier` Parameter to children components.
    ///
    /// Example:
    /// The `@Parameter` property used as a path parameter can also be defined outside the component as part of a Group that contains the `Component`.
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
        return self
    }

    public func option<Option>(for key: OptionKey<Option>) -> Option? {
        return options.option(for: key)
    }

    public init() {
        self.options = PropertyOptionSet()
    }
    
    public init(_ options: Option...) {
        self.options = PropertyOptionSet(options)
    }

    public init(wrappedValue defaultValue: Element, _ name: String) {
        self.name = name
        self.options = PropertyOptionSet()
        self.defaultValue = defaultValue
    }

    public init(wrappedValue defaultValue: Element) {
        self.options = PropertyOptionSet()
        self.defaultValue = defaultValue
    }

    /// - Parameters:
    ///   - name: The name used to describe the wrapped property for in the web APIs
    ///   - parameterType: The `ParameterType` that explicitly describes the type of parameter that should be used for the wrapped property
    public init(_ name: String, _ options: Option...) {
        self.name = name
        self.options = PropertyOptionSet(options)
    }
    
    private init(name: String?, options: PropertyOptionSet<ParameterOptionNameSpace>, id: UUID) {
        self.name = name
        self.options = options
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
