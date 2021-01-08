//
// Created by Andi on 08.01.21.
//

import Foundation
import class Vapor.Application

/// This configuration provides a way to alter the configuration of `JSONEncoder` instances used in Apodini.
/// As `JSONEncoder` is declared `open`, it also allows for supplying your own subclass.
///
/// A JSONEncoderConfiguration definition for the standard `JSONEncoder` could look like the following:
/// ```swift
/// @ConfigurationBuilder
/// var configuration: some Configuration {
///     JSONEncoderConfiguration()
///         .with(\.outputFormatting, value: [.withoutEscapingSlashes, .prettyPrinted])
///         .with(\.dateEncodingStrategy, value: .secondsSince1970)
/// }
/// ```
public struct JSONEncoderConfiguration<Encoder: JSONEncoder>: Configuration {
    private let initializer: () -> Encoder
    private var configurations: [AnyKeyPathConfiguration<Encoder>] = []

    /// Creates a new `JSONEncoderConfiguration` instance with a custom `JSONEncoder` implementation.
    public init(_ initializer: @escaping @autoclosure () -> Encoder) {
        self.initializer = initializer
    }

    public func with<Value>(_ property: WritableKeyPath<Encoder, Value>, value: Value) -> Self {
        var configuration = self
        configuration.configurations.append(KeyPathConfiguration(property, value: value))
        return configuration
    }

    public func configure(_ app: Application) {
        // TODO somehow store this configuration so Exporters can access it
    }

    func instance() -> Encoder {
        var encoder = initializer()
        for configuration in configurations {
            configuration.apply(to: &encoder)
        }
        return encoder
    }
}

extension JSONEncoderConfiguration where Encoder == JSONEncoder {
    /// Creates a new instance of `JSONEncoderConfiguration` using the standard `JSONEncoder`.
    public init() {
        self.initializer = { JSONEncoder() }
    }
}

class AnyKeyPathConfiguration<Root> {
    func apply(to instance: inout Root) {
        fatalError("\(self) did not properly overwrite apply of AnyKeyPathConfiguration!")
    }
}

class KeyPathConfiguration<Root, Value>: AnyKeyPathConfiguration<Root> {
    let keyPath: WritableKeyPath<Root, Value>
    let value: Value

    init(_ keyPath: WritableKeyPath<Root, Value>, value: Value) {
        self.keyPath = keyPath
        self.value = value
        super.init()
    }

    override func apply(to instance: inout Root) {
        instance[keyPath: keyPath] = value
    }
}
