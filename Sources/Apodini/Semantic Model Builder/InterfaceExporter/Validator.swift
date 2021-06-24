//
//  Validator.swift
//  
//
//  Created by Max Obermeier on 01.01.21.
//

import Foundation
import NIO
import ApodiniUtils
@_implementationOnly import AssociatedTypeRequirementsVisitor

// MARK: Protocols

/// A `Validator` is a stateful construct that checks incoming `request`s for a specific connection
/// handled by a specific `InterfaceExporter`.
protocol Validator {
    associatedtype Exporter: InterfaceExporter
    associatedtype Input
    associatedtype Output
    
    /// Checks if the `request` is valid by the `Validator`'s criteria.
    /// - Throws: A `ValidationError` is thrown if `request` is invalid for the current state.
    /// - Invariant: The function must not mutate `self` if an error is thrown.
    mutating func validate(_ request: Exporter.ExporterRequest, with input: Input) throws -> Output
    
    /// Resets the `Validator` to its state before the most recent call to `validate`. This can be
    /// used to reset the `Validator` if execution was aborted due to some logic that is **not**
    /// covered by this `Validator`.
    mutating func reset()
}

// MARK: AnyValidator

struct AnyValidator<E: InterfaceExporter, I, O>: Validator {
    typealias Exporter = E
    typealias Output = O
    typealias Input = I
    
    private var validateFunc: (_ request: E.ExporterRequest, _ input: I) throws -> O
    
    private var resetFunc: () -> Void
    
    init<V: Validator>(_ validator: V) where V.Exporter == E, V.Output == O, V.Input == I {
        var validator = validator
        
        self.validateFunc = { request, input throws in
            try validator.validate(request, with: input)
        }
        
        self.resetFunc = {
            validator.reset()
        }
    }
    
    mutating func validate(_ request: E.ExporterRequest, with input: I) throws -> O {
        try validateFunc(request, input)
    }
    
    mutating func reset() {
        resetFunc()
    }
}

extension Validator {
    func eraseToAnyValidator() -> AnyValidator<Exporter, Input, Output> {
        AnyValidator(self)
    }
}

// MARK: Endpoint Validation

extension Endpoint {
    func validator<I: InterfaceExporter>(for exporter: I) -> AnyValidator<I, EventLoop, ValidatingRequest<I, H>> {
        EndpointValidator(for: exporter, on: self).eraseToAnyValidator()
    }
}

internal class EndpointValidator<I: InterfaceExporter, H: Handler>: Validator {
    typealias Exporter = I
    
    private let exporter: I
    
    private var validators: [UUID: AnyValidator<I, Void, Any>]
    
    private let endpoint: Endpoint<H>
    
    private var validated: [UUID: Any] = [:]
    
    private var request: I.ExporterRequest?
    
    fileprivate init(
        for exporter: I,
        on endpoint: Endpoint<H>
    ) {
        self.exporter = exporter
        self.endpoint = endpoint
        self.validators = endpoint[EndpointParameters.self].reduce(into: [UUID: AnyValidator<I, Void, Any>]()) { validators, parameter in
            validators[parameter.id] = parameter.toInternal().representative(for: exporter)
        }
    }
    
    
    func validate(_ request: I.ExporterRequest, with eventLoop: EventLoop) throws -> ValidatingRequest<I, H> {
        self.validated = [:]
        self.request = request
        
        return ValidatingRequest<I, H>(
            for: exporter,
            with: request,
            using: self,
            on: endpoint,
            running: eventLoop
        )
    }
    
    func validate<V>(one parameter: UUID) throws -> V {
        if let cachedResult = validated[parameter] {
            guard let typedResult = cachedResult as? V else {
                fatalError("Validation failed to detect wrong type or wrong type was requested for parameter.")
            }
            return typedResult
        }
        
        guard let request = self.request else {
            fatalError("EndpointValidator tried to validate parameter while no request was present.")
        }
        
        guard var validator = self.validators[parameter] else {
            throw ApodiniError(type: .badInput, description: "EndpointValidator tried to validate an unknown parameter.")
        }
        
        do {
            let result = try validator.validate(request, with: Void())
            self.validators[parameter] = validator
            validated[parameter] = result
            
            guard let typedResult = result as? V else {
                fatalError("Validation failed to detect wrong type or wrong type was requested for parameter.")
            }
            
            return typedResult
        } catch {
            for (id, _) in validated {
                if var validator = validators[id] {
                    validator.reset()
                    validators[id] = validator
                }
            }
            validated = [:]
            throw error
        }
    }
    
    func reset() {
        for (id, _) in validators {
            validators[id]?.reset()
        }
        self.validated = [:]
    }
}

private extension _AnyEndpointParameter {
    func representative<I: InterfaceExporter>(for exporter: I) -> AnyValidator<I, Void, Any> {
        let builder = RepresentativeBuilder<I>(exporter)
        return self.accept(builder)
    }
}

private class RepresentativeBuilder<I: InterfaceExporter>: EndpointParameterVisitor {
    private let exporter: I
    
    init(_ exporter: I) {
        self.exporter = exporter
    }
    
    func visit<Element: Codable>(parameter: EndpointParameter<Element>) -> AnyValidator<I, Void, Any> {
        AnyValidator<I, Void, Any>(ParameterRepresentative<Element, I>(definition: parameter, exporter: self.exporter))
    }
}

// MARK: Parameter Validation

extension ParameterRepresentative: Validator {
    typealias Exporter = E
    
    typealias Input = Void
    
    typealias Output = Any
    
    mutating func validate(_ request: E.ExporterRequest, with input: Void) throws -> Any {
        let typedValue: Type?? = try exporter.retrieveParameter(self.definition, for: request)
        
        try checkNecessity(of: typedValue)
        let result = try checkNullability(of: typedValue)
        try checkMutability(of: typedValue)
        
        return result
    }
}


/// Handles all checks done for a Parameter, meaning checking that a value is present for a required parameter
/// and for optional parameters setting a optionally supplied default value, as well as checking that constant
/// parameters are not altered after the initial request.
///
/// Those four main cases are handled in regards to necessity and nullability:
/// ```@Parameter var value: String``` required, no default value, "explicit nil" not valid
/// ```@Parameter var value: String?``` optional, no default value, "explicit nil" is valid, nilIsValidValue=true
/// ```@Parameter var value: String = "ASdf"``` optional, with default value, "explicit nil" not valid
/// ```@Parameter var value: String? = "ASdf"``` optional, with default value, "explicit nil" is valid, nilIsValidValue=true
private struct ParameterRepresentative<Type: Codable, E: InterfaceExporter> {
    let definition: EndpointParameter<Type>
    
    let defaultValue: Type?
    
    let exporter: E
    
    init(definition: EndpointParameter<Type>, exporter: E) {
        self.definition = definition
        self.exporter = exporter
        self.defaultValue = definition.defaultValue?()
    }
    
    private var _initialValueBackup: Type??
    private var initialValue: Type??
    
    func checkNecessity(of value: Type??) throws {
        if value == nil {
            // Result is nil, meaning retrieveParameter returned nil, meaning
            // the exporter encoded that there was no value provided for this parameter.
            // => NON EXISTENCE
            
            switch definition.necessity {
            case .required:
                throw ApodiniError(type: .badInput, reason: "Didn't retrieve any parameters for a required '\(definition.description)'.")
            case .optional:
                break
            }
        }
    }
    
    func checkNullability(of value: Type??) throws -> Any {
        if let retrievedValue = value,
           retrievedValue == nil && !definition.nilIsValidValue {
            throw ApodiniError(type: .badInput, reason: "Parameter retrieval returned explicit nil, though explicit nil is not valid for the '\(definition.description)'.")
        }
        
        if definition.nilIsValidValue {
            // return type must be an `Optional<Type>`
            let result: Type? = value ?? defaultValue
            return result as Any
        } else {
            // return type must be just `Type`
            guard let unwrappedValue = (value ?? defaultValue) else {
                fatalError("Could not unwrap opiontal value for \(definition.description) even though it is not an optional. This should have been detected by 'checkNecessity'.")
            }
            let result: Type = unwrappedValue
            return result as Any
        }
    }
    
    mutating func checkMutability(of value: Type??) throws {
        self._initialValueBackup = self.initialValue
        
        if let retrievedValue = value {
            switch definition.options.option(for: .mutability) ?? .variable {
            case .constant:
                if let initialValue = self.initialValue {
                    if !AnyEquatable.compare(initialValue as Any, retrievedValue as Any).isEqual {
                        throw ApodiniError(type: .badInput, reason: "Parameter retrieval returned value for constant '\(definition.description)' even though its value has already been defined.")
                    }
                } else {
                    self.initialValue = retrievedValue
                }
            case .variable:
                break
            }
        } else if let defaultValue = self.defaultValue {
            self.initialValue = defaultValue
        }
    }
    
    mutating func reset() {
        self.initialValue = _initialValueBackup
    }
}
