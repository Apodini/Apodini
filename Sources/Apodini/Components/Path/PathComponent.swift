//
//  PathComponent.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

/// A full path is built out of multiple PathComponents
public protocol PathComponent {}

protocol _PathComponent: PathComponent {
    func append<Parser: PathComponentParser>(to parser: inout Parser)
}

extension _PathComponent {
    func accept<Parser: PathComponentParser>(_ parser: inout Parser) {
        if let parsable = self as? PathComponentModifier {
            parsable.accept(&parser)
        } else {
            append(to: &parser)
        }
    }
}

extension PathComponent {
    func toInternal() -> _PathComponent {
        guard let pathComponent = self as? _PathComponent else {
            fatalError("Encountered `PathComponent` which doesn't conform to `_PathComponent`: \(self)!")
        }
        return pathComponent
    }
}

extension String: _PathComponent {
    func append<Parser: PathComponentParser>(to parser: inout Parser) {
        parser.visit(self)
    }
}
