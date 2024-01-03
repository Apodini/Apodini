//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

struct MarkGroupEndModifierContextKey: OptionalContextKey {
    typealias Value = Bool
}

struct MarkGroupEndModifier: PathComponentModifier {
    let pathComponent: any _PathComponent

    init(_ pathComponent: any PathComponent) {
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

extension Array where Element == any PathComponent {
    mutating func markEnd() {
        if let last = self.last {
            self[endIndex - 1] = last.markGroupEnd()
        }
    }
}
