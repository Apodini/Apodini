//
//  Body.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import Foundation


/// Generic Parameter that can be used to mark that the options are meant for `@Parameter`s
public enum ParameterOptionNameSpace { }

public protocol AnyParameterID {
    var value: UUID { get }
}


/// The `@Parameter` property wrapper can be used to express input in `Components`
@propertyWrapper
public struct Parameter<Element: Codable>: Property {
    /// Keys for options that can be passed to an `@Parameter` property wrapper
    public typealias OptionKey<T: PropertyOption> = PropertyOptionKey<ParameterOptionNameSpace, T>
    /// Type erased options that can be passed to an `@Parameter` property wrapper
    public typealias Option = AnyPropertyOption<ParameterOptionNameSpace>

    
    let id: UUID
    let name: String?
    
    internal let options: PropertyOptionSet<ParameterOptionNameSpace>
    internal let defaultValue: (() -> Element)?
    
    private var element: Element?
    
    
    /// The value for the `@Parameter` as defined by the incoming request
    public var wrappedValue: Element {
        guard let element = element else {
            fatalError("You can only access a parameter while you handle a request")
        }
        
        return element
    }
    
    
    // This is here because, other than a `@Parameter` property itself (ie the storage), the projected value
    // isn't private, meaning that we can use this to specify a parameter when remote-invoking a handler.
    // We could alwo make the projectedValue return self, although it seems like a better idea to limit ourselves
    // to having to use the identifier to retrieve (and use) the endpoint parameter.
    public struct ID: AnyParameterID {
        public let value: UUID
    }
    public var projectedValue: ID { ID(value: self.id) }


    private init(
        id: UUID = UUID(),
        name: String? = nil,
        defaultValue: (() -> Element)? = nil,
        options: [Option] = []
    ) {
        if let name = name {
            precondition(!name.isEmpty, "The name for Parameter cannot be empty!")
        }

        self.id = id
        self.defaultValue = defaultValue
        self.name = name
        self.options = PropertyOptionSet(options)

        if option(for: PropertyOptionKey.http) == .path {
            precondition(!isOptional(Element.self), "A `PathParameter` cannot annotate a property with Optional type!")
        }
    }
    
    
    /// Creates a new `@Parameter` that indicates input of a `Component` without a default value, different name for the encoding, or special options.
    public init() {
        // We need to pass any argument otherwise we would call the same initializer again resulting in a infinite loop
        self.init(id: UUID())
    }
    
    /// Creates a new `@Parameter` that indicates input of a `Component`.
    /// - Parameters:
    ///   - name: The name that identifies this property when decoding the property from the input of a `Component`
    ///   - options: Options passed on to different interface exporters to clarify the functionality of this `@Parameter` for different API types
    public init(_ name: String, _ options: Option...) {
        self.init(name: name, options: options)
    }

    /// Creates a new `@Parameter` that indicates input of a `Component`.
    /// - Parameters:
    ///   - options: Options passed on to different interface exporters to clarify the functionality of this `@Parameter` for different API types
    public init(_ options: Option...) {
        self.init(options: options)
    }
    
    /// Creates a new `@Parameter` that indicates input of a `Component`.
    /// - Parameters:
    ///   - defaultValue: The default value that should be used in case the interface exporter can not decode the value from the input of the `Component`
    ///   - name: The name that identifies this property when decoding the property from the input of a `Component`
    ///   - options: Options passed on to different interface exporters to clarify the functionality of this `@Parameter` for different API types
    public init(wrappedValue defaultValue: @autoclosure @escaping () -> Element, _ name: String, _ options: Option...) {
        self.init(name: name, defaultValue: defaultValue, options: options)
    }
    
    /// Creates a new `@Parameter` that indicates input of a `Component`.
    /// - Parameters:
    ///   - defaultValue: The default value that should be used in case the interface exporter can not decode the value from the input of the `Component`
    ///   - options: Options passed on to different interface exporters to clarify the functionality of this `@Parameter` for different API types
    public init(wrappedValue defaultValue: @autoclosure @escaping () -> Element, _ options: Option...) {
        self.init(defaultValue: defaultValue, options: options)
    }
    
    /// Creates a new `@Parameter` that indicates input of a `Component`.
    /// - Parameters:
    ///   - defaultValue: The default value that should be used in case the interface exporter can not decode the value from the input of the `Component`
    public init(wrappedValue defaultValue: @autoclosure @escaping () -> Element) {
        self.init(defaultValue: defaultValue)
    }
    
    /// Creates a new `@Parameter` that indicates input of a `Component's` `@PathParameter` based on an existing component.
    /// - Parameter id: The `UUID` that can be passed in from a parent `Component`'s `@PathParameter`.
    /// - Precondition: A `@Parameter` with a specific `http` type `.body` or `.query` can not be passed to a separate component. Please remove the specific `.http` property option or specify the `.http` property option to `.path`.
    init(from id: UUID, identifying type: IdentifyingType?) {
        var pathParameterOptions: [Option] = [.http(.path)]
        if let type = type {
            pathParameterOptions.append(.identifying(type))
        }

        self.init(id: id, options: pathParameterOptions)
    }
    
    
    func option<Option>(for key: OptionKey<Option>) -> Option? {
        options.option(for: key)
    }
}

extension Parameter: RequestInjectable {
    mutating func inject(using request: Request) {
        do {
            element = try request.retrieveParameter(self)
        } catch {
            fatalError("Injection failed: \(self.id) could not be retrieved from \(request). This was probably caused by a bug/inconsistency in the validation.")
        }
    }

    func accept(_ visitor: RequestInjectableVisitor) {
        visitor.visit(self)
    }
}

extension Parameter: _PathComponent {
    func append<Parser: PathComponentParser>(to parser: inout Parser) {
        parser.visit(self)
    }
}
