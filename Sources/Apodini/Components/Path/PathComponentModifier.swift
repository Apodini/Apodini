//
// Created by Andreas Bauer on 05.01.21.
//

protocol PathComponentModifier: _PathComponent {
    var pathComponent: _PathComponent { get }

    func accept<Parser: PathComponentParser>(_ parser: inout Parser)
}

extension PathComponentModifier {
    var pathDescription: String {
        fatalError("Can't retrieve pathDescription for a PathComponentModifier!")
    }

    func append<Parser>(to parser: inout Parser) where Parser: PathComponentParser {
        fatalError("Can't append PathComponentModifier to anything!")
    }
}
