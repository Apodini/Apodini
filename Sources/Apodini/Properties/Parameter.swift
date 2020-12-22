//
//  Body.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import Vapor
import Foundation


/// Generic Parameter that can be used to mark that the options are meant for `@Parameter`s
public enum ParameterOptionNameSpace { }

/// The `@Parameter` property wrapper can be used to express input in `Components`
@propertyWrapper
public struct Parameter<Element: Codable>: Property {
    /// Keys for options that can be passed to an `@Parameter` property wrapper
    public typealias OptionKey<T: PropertyOption> = PropertyOptionKey<ParameterOptionNameSpace, T>
    /// Type erased options that can be passed to an `@Parameter` property wrapper
    public typealias Option = AnyPropertyOption<ParameterOptionNameSpace>

    
    var id = UUID()
    var name: String?
    private var element: Element?
    internal var options: PropertyOptionSet<ParameterOptionNameSpace>
    private var defaultValue: Element?
    
    
    /// The value for the `@Parameter` as defined by the incoming request
    public var wrappedValue: Element {
        guard let element = element else {
            fatalError("You can only access the body while you handle a request")
        }
        
        return element
    }
    
    
    /// Creates a new `@Parameter` that indicates input of a `Component` without a default value, different name for the encoding, or special options.
    public init() {
        self.defaultValue = nil
        self.name = nil
        self.options = PropertyOptionSet()
    }
    
    /// Creates a new `@Parameter` that indicates input of a `Component`.
    /// - Parameters:
    ///   - name: The name that identifies this property when decoding the property from the input of a `Component`
    ///   - options: Options passed on to different interface exporters to clarify the functionality of this `@Parameter` for different API types
    public init(_ name: String? = nil, _ options: Option...) {
        self.defaultValue = nil
        self.name = name
        self.options = PropertyOptionSet(options)
    }
    
    /// Creates a new `@Parameter` that indicates input of a `Component`.
    /// - Parameters:
    ///   - defaultValue: The default value that should be used in case the interface exporter can not decode the value from the input of the `Component`
    ///   - name: The name that identifies this property when decoding the property from the input of a `Component`
    ///   - options: Options passed on to different interface exporters to clarify the functionality of this `@Parameter` for different API types
    public init(wrappedValue defaultValue: Element, _ name: String? = nil, _ options: Option...) {
        self.defaultValue = defaultValue
        self.name = name
        self.options = PropertyOptionSet(options)
    }
    
    /// Creates a new `@Parameter` that indicates input of a `Component's` `@PathParameter` based on an existing component.
    /// - Parameter id: The `UUID` that can be passed in from a parent `Component`'s `@PathParameter`.
    /// - Precondition: A `@Parameter` with a specific `http` type `.body` or `.query` can not be passed to a seperate componet. Please remove the specific `.http` property option or specify the `.http` property option to `.path`.
    init(_ id: UUID) {
        self.options = PropertyOptionSet([.http(.path)])
        self.id = id
    }
    
    
    func option<Option>(for key: OptionKey<Option>) -> Option? {
        options.option(for: key)
    }
}


extension Parameter: RequestInjectable {
    mutating func inject(using request: Vapor.Request, with decoder: RequestInjectableDecoder?) throws {
        if let decoder = decoder {
            element = try decoder.decode(Element.self, from: request)
        }
    }

    func accept(_ visitor: RequestInjectableVisitor) {
        visitor.visit(self)
    }
}


extension Parameter: _PathComponent {
    var description: String {
        ":\(self.id)"
    }
    
    func append<P>(to pathBuilder: inout P) where P: PathBuilder {
        pathBuilder.append(self)
    }
}
