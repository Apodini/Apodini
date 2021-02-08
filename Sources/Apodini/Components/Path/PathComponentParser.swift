//
// Created by Andreas Bauer on 05.01.21.
//

protocol PathComponentParser {
    mutating func addContext<C: OptionalContextKey>(_ contextKey: C.Type, value: C.Value)

    mutating func visit(_ string: String)
    mutating func visit(_ version: Version)
    mutating func visit<T>(_ parameter: Parameter<T>)
}

extension PathComponentParser {
    // simple parsers like the `StringPathBuilder` don't need to store the context
    mutating func addContext<C: OptionalContextKey>(_ contextKey: C.Type, value: C.Value) {}

    mutating func visit(_ version: Version) {
        visit(version.description)
    }
}


extension Array where Element == PathComponent {
    func asPathString(delimiter: String = "/") -> String {
        PathComponentStringBuilder(self, delimiter: delimiter).build()
    }
}

extension Array where Element == _PathComponent {
    func asPathString(delimiter: String = "/") -> String {
        PathComponentStringBuilder(self, delimiter: delimiter).build()
    }
}

private struct PathComponentStringBuilder: PathComponentParser {
    private let delimiter: String
    private var paths: [String] = []

    init(_ pathComponents: [PathComponent], delimiter: String = "/") {
        self.delimiter = delimiter

        for pathComponent in pathComponents {
            let pathComponent = pathComponent.toInternal()
            pathComponent.accept(&self)
        }
    }

    mutating func visit(_ string: String) {
        paths.append(string)
    }

    mutating func visit<T>(_ parameter: Parameter<T>) {
        paths.append(parameter.id.uuidString)
    }

    func build() -> String {
        paths.joined(separator: delimiter)
    }
}
