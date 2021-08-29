//
// Created by Andreas Bauer on 28.08.21.
//

import Foundation
import OpenAPIKit

struct CoreContext: JSONContext {
    var context: ContextName = .core

    enum Property: String {
        case format
        case required
        case nullable
        case permissions
        case deprecated
        case title
        case description
        case discriminator
        case externalDocs
        case allowedValues
        case defaultValue
        case example
    }

    typealias Permissions = JSONSchema.CoreContext<JSONTypeFormat.AnyFormat>.Permissions

    static var required = PropertyDescription(context: Self.self, property: .required, type: Bool.self)
    static var nullable = PropertyDescription(context: Self.self, property: .nullable, type: Bool.self)
    static var permissions = PropertyDescription(context: Self.self, property: .permissions, type: Permissions.self)
    static var deprecated = PropertyDescription(context: Self.self, property: .deprecated, type: Bool.self)
    static var title = PropertyDescription(context: Self.self, property: .title, type: String.self)
    static var description = PropertyDescription(context: Self.self, property: .description, type: String.self)
    static var discriminator = PropertyDescription(context: Self.self, property: .discriminator, type: OpenAPIKit.OpenAPI.Discriminator.self)
    static var externalDocs = PropertyDescription(context: Self.self, property: .externalDocs, type: OpenAPIKit.OpenAPI.ExternalDocumentation.self)
    static var allowedValues = PropertyDescription(context: Self.self, property: .allowedValues, type: Array<AnyCodable>.self)
    static var defaultValue = PropertyDescription(context: Self.self, property: .defaultValue, type: AnyCodable.self)
    static var example = PropertyDescription(context: Self.self, property: .example, type: AnyCodable.self)
}
