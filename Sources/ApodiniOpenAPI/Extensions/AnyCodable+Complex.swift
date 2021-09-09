//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import OpenAPIKit
import ApodiniUtils

public extension AnyCodable {
    /// Initialize a `AnyCodable` which is not one of the supported standard types.
    static func fromComplex<Element: Encodable>(_ element: Element) -> AnyCodable {
        fromComplex(element, anyElement: element)
    }

    /// Initialize a `AnyCodable` which is not one of the supported standard types.
    static func fromComplex(_ element: AnyEncodable) -> AnyCodable {
        fromComplex(element, anyElement: element.wrappedValue)
    }

    private static func fromComplex<Element: Encodable>(_ element: Element, anyElement: Any) -> AnyCodable {
        let encoder = JSONEncoder()
        do {
            // if encoding works, we don't need to execute the workaround below :/
            _ = try encoder.encode(AnyCodable(anyElement))
            return AnyCodable(anyElement)
        } catch {
            // ignored
        }

        let encoded: Data
        do {
            encoded = try encoder.encode(element)
        } catch {
            fatalError("Unable to encode \(Element.self). Failed with \(error)")
        }

        let json: Any
        do {
            json = try JSONSerialization.jsonObject(with: encoded, options: [])
        } catch {
            fatalError("Failed to serialize json encoded string: \(String(data: encoded, encoding: .utf8) ?? "<ERR>") [\(element)]: \(error)")
        }

        return AnyCodable(json)
    }
}
