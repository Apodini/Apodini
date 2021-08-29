//
// Created by Andreas Bauer on 28.08.21.
//

import Foundation
import OpenAPIKit

public extension AnyCodable {
    static func fromComplex<Element: Encodable>(_ element: Element) -> AnyCodable {
        let encoder = JSONEncoder()
        do {
            // if encoding works, we don't need to execute the workaround below :/
            _ = try encoder.encode(AnyCodable(element))
            return AnyCodable(element)
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
            // TODO array works too?
            json = try JSONSerialization.jsonObject(with: encoded, options: [])
        } catch {
            fatalError("Failed to serialize json encoded string: \(String(data: encoded, encoding: .utf8) ?? "<ERR>") [\(element)]: \(error)")
        }

        #if DEBUG
        do {
            // verify that encoding works actually
            _ = try encoder.encode(AnyCodable(json))
        } catch {
            fatalError("Failsafe failed: failed with \(error) to encoder OpenAPIKit AnyCodable\(json)!")
        }
        #endif

        return AnyCodable(json)
    }
}
