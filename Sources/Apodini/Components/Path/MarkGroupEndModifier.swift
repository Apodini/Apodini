//
// Created by Andreas Bauer on 24.01.21.
//

struct MarkGroupEndModifierContextKey: OptionalContextKey {
    typealias Value = Bool
}

struct MarkGroupEndModifier: PathComponentModifier {
    let pathComponent: _PathComponent

    init(_ pathComponent: PathComponent) {
        self.pathComponent = pathComponent.toInternal()
    }

    func accept<Parser: PathComponentParser>(_ parser: inout Parser) {
        parser.addContext(MarkGroupEndModifierContextKey.self, value: true)
        pathComponent.accept(&parser)
    }
}

extension PathComponent {
    func markGroupEnd() -> MarkGroupEndModifier {
        MarkGroupEndModifier(self)
    }
}

extension Array where Element == PathComponent {
    mutating func markEnd() {
        if let last = self.last {
            self[endIndex - 1] = last.markGroupEnd()
        }
    }
}
