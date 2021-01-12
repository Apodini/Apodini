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
    var description: String { get }

    func append<P: PathBuilder>(to pathBuilder: inout P)
}


protocol PathBuilder {
    mutating func append(_ string: String)
    mutating func append<T>(_ parameter: Parameter<T>)
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

    mutating func append<T>(_ parameter: Parameter<T>) {
        paths.append(parameter.description)
    }

    func build() -> String {
        paths.joined(separator: delimiter)
    }
}


extension String: _PathComponent {
    var description: String {
        self
    }

    func append<P>(to pathBuilder: inout P) where P: PathBuilder {
        pathBuilder.append(self)
    }
}


extension Array where Element == _PathComponent {
    func joinPathComponents(separator: String = "/") -> String {
        self.map(\.description).joined(separator: separator)
    }
}
