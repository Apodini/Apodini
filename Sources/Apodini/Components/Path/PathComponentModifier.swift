//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

protocol PathComponentModifier: _PathComponent {
    var pathComponent: any _PathComponent { get }

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
