//
//  PathComponent.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import Foundation


/// A full path is built out of multiple PathComponents
public protocol PathComponent {}

protocol _PathComponent: PathComponent {
    func append<P: PathBuilder>(to pathBuilder: inout P)
}

protocol PathBuilder {
    mutating func append(_ string: String)
    mutating func append<T>(_ identifier: Identifier<T>)
}

struct StringPathBuilder: PathBuilder {
    private let delimiter: String
    private var paths: [String] = []

    init(_ pathComponents: [PathComponent], delimiter: String = "/") {
        self.delimiter = delimiter

        for pathComponent in pathComponents {
            if let pathComponent = pathComponent as? _PathComponent {
                pathComponent.append(to: &self)
            }
        }
    }

    mutating func append(_ string: String) {
        paths.append(string)
    }

    mutating func append<T>(_ identifier: Identifier<T>) where T: Identifiable {
        paths.append(identifier.identifier)
    }

    func build() -> String {
        paths.joined(separator: delimiter)
    }
}


extension String: _PathComponent {
    func append<P>(to pathBuilder: inout P) where P: PathBuilder {
        pathBuilder.append(self)
    }
}

/// Used to define parameter in a path
public struct Identifier<T: Identifiable> {
    let identifier: String

    /// This initializes a new Identifier which is used to identify the given `type`.
    public init(_ type: T.Type = T.self) {
        let typeName = String(describing: T.self).uppercased()
        identifier = "\(typeName)-\(UUID())"
    }
}

extension Identifier: _PathComponent {
    func append<P>(to pathBuilder: inout P) where P: PathBuilder {
        pathBuilder.append(self)
    }
}
