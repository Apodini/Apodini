//
//  Body.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

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
    internal var defaultValue: (() -> Element)?
    
    
    /// The value for the `@Parameter` as defined by the incoming request
    public var wrappedValue: Element {
        guard let element = element else {
            fatalError("You can only access a parameter while you handle a request")
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
    public init(_ name: String, _ options: Option...) {
        self.defaultValue = nil
        self.name = name
        self.options = PropertyOptionSet(options)
    }
    
    /// Creates a new `@Parameter` that indicates input of a `Component`.
    /// - Parameters:
    ///   - options: Options passed on to different interface exporters to clarify the functionality of this `@Parameter` for different API types
    public init(_ options: Option...) {
        self.defaultValue = nil
        self.name = nil
        self.options = PropertyOptionSet(options)
    }
    
    /// Creates a new `@Parameter` that indicates input of a `Component`.
    /// - Parameters:
    ///   - defaultValue: The default value that should be used in case the interface exporter can not decode the value from the input of the `Component`
    ///   - name: The name that identifies this property when decoding the property from the input of a `Component`
    ///   - options: Options passed on to different interface exporters to clarify the functionality of this `@Parameter` for different API types
    public init(wrappedValue defaultValue: @autoclosure @escaping () -> Element, _ name: String, _ options: Option...) {
        self.defaultValue = defaultValue
        self.name = name
        self.options = PropertyOptionSet(options)
    }
    
    /// Creates a new `@Parameter` that indicates input of a `Component`.
    /// - Parameters:
    ///   - defaultValue: The default value that should be used in case the interface exporter can not decode the value from the input of the `Component`
    ///   - options: Options passed on to different interface exporters to clarify the functionality of this `@Parameter` for different API types
    public init(wrappedValue defaultValue: @autoclosure @escaping () -> Element, _ options: Option...) {
        self.defaultValue = defaultValue
        self.name = nil
        self.options = PropertyOptionSet(options)
    }
    
    /// Creates a new `@Parameter` that indicates input of a `Component`.
    /// - Parameters:
    ///   - defaultValue: The default value that should be used in case the interface exporter can not decode the value from the input of the `Component`
    public init(wrappedValue defaultValue: @autoclosure @escaping () -> Element) {
        self.defaultValue = defaultValue
        self.name = nil
        self.options = PropertyOptionSet([])
    }
    
    /// Creates a new `@Parameter` that indicates input of a `Component's` `@PathParameter` based on an existing component.
    /// - Parameter id: The `UUID` that can be passed in from a parent `Component`'s `@PathParameter`.
    /// - Precondition: A `@Parameter` with a specific `http` type `.body` or `.query` can not be passed to a separate component. Please remove the specific `.http` property option or specify the `.http` property option to `.path`.
    init(from id: UUID) {
        self.options = PropertyOptionSet([.http(.path)])
        self.id = id
        self.defaultValue = nil
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
