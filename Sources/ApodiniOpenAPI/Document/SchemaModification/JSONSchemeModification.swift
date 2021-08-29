//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import OpenAPIKit

/// Defines a modification to a `Content` type.
public enum JSONSchemeModificationType {
    /// The modification applies to the `Content` type itself.
    case root(modification: AnyJSONContextModification)
    /// The modification applies to a property of the `Content` type.
    case property(property: String, modification: AnyJSONContextModification)
}

private extension Array where Element == JSONSchemeModificationType {
    func rootModifications() -> JSONSchemeModification.Modifications {
        reduce(into: [:]) { result, modification in
            if case let .root(modification) = modification {
                result[modification.anyKey] = modification
            }
        }
    }

    func propertyModifications() -> [String: JSONSchemeModification.Modifications] {
        reduce(into: [:]) { result, modification in
            guard case let .property(property, modification) = modification else {
                return
            }

            result[property, default: [:]][modification.anyKey] = modification
        }
    }
}


struct JSONSchemeModification {
    typealias Modifications = [AnyHashable: AnyJSONContextModification]
    typealias PropertyModifications = [String: Modifications]

    private var rootModifications: Modifications
    private var propertyModifications: PropertyModifications

    var hasPendingPropertyModifications: Bool {
        !propertyModifications.isEmpty
    }

    init(root modification: AnyJSONContextModification) {
        self.init(with: [.root(modification: modification)])
    }

    init(with modifications: [JSONSchemeModificationType]) {
        self.rootModifications = modifications.rootModifications()
        self.propertyModifications = modifications.propertyModifications()
    }

    mutating func mapContextKeys(from context: Context) {
        if let description = context.get(valueFor: DescriptionContextKey.self) {
            let modification = PropertyModification(context: CoreContext.self, property: .description, value: description)
            rootModifications[modification.key] = modification
        }
    }

    func callAsFunction(on scheme: JSONSchema) -> JSONSchema {
        applyModifications(on: scheme, considering: rootModifications)
    }

    func completePendingModifications(for key: OpenAPIKit.OpenAPI.ComponentKey, in components: OpenAPIKit.OpenAPI.Components) throws -> JSONSchema {
        guard let schema = components.schemas[key] else {
            fatalError("Schema \(key) got lost. Tried evaluating property modifications.")
        }
        precondition(!schema.isReference, "Unexpected reference!")

        guard case let .object(coreContext, objectContext) = schema else {
            preconditionFailure("Unexpected non object with properties!")
        }


        var updateProperties: [String: JSONSchema] = objectContext.properties

        for (property, propertyModifications) in propertyModifications {
            guard var jsonProperty = objectContext.properties[property] else {
                Application.logger.warning("""
                                           ApodiniOpenAPI: Found a scheme modification for \(property) [\(propertyModifications)]; \
                                           not present in scheme \(schema)!
                                           """)
                continue
            }

            if jsonProperty.isReference {
                jsonProperty = try jsonProperty.rootDereference(in: components)
            }

            let modifiedProperty = applyModifications(on: jsonProperty, considering: propertyModifications)
            // save the modified scheme
            updateProperties[property] = modifiedProperty
        }

        let modification = JSONSchemeModification(
            root: PropertyModification(context: ObjectContext.self, property: .properties, value: updateProperties)
        )

        return modification(on: schema)
    }

    private func applyModifications(on scheme: JSONSchema, considering modifications: Modifications) -> JSONSchema {
        if modifications.isEmpty {
            return scheme
        }

        switch scheme {
        case let .boolean(coreContext):
            return .boolean(
                modifyCoreContext(coreContext, considering: modifications)
            )
        case let .number(coreContext, numericContext):
            return .number(
                modifyCoreContext(coreContext, considering: modifications),
                modifyNumericContext(numericContext, considering: modifications)
            )
        case let .integer(coreContext, integerContext):
            return .integer(
                modifyCoreContext(coreContext, considering: modifications),
                modifyIntegerContext(integerContext, considering: modifications)
            )
        case let .string(coreContext, stringContext):
            return .string(
                modifyCoreContext(coreContext, considering: modifications),
                modifyStringContext(stringContext, considering: modifications)
            )
        case let .object(coreContext, objectContext):
            return .object(
                modifyCoreContext(coreContext, considering: modifications),
                modifyObjectContext(objectContext, considering: modifications)
            )
        case let .array(coreContext, arrayContext):
            return .array(
                modifyCoreContext(coreContext, considering: modifications),
                modifyArrayContext(arrayContext, considering: modifications)
            )
        default:
            return scheme
        }
    }

    private func modifyCoreContext<Format>(
        _ context: JSONSchema.CoreContext<Format>,
        considering modifications: Modifications
    ) -> JSONSchema.CoreContext<Format> {
        let mirror = Mirror(reflecting: context)

        let contextPermissions: JSONSchema.CoreContext<Format>.Permissions?
        if let permissions = modify(property: CoreContext.permissions, considering: modifications) {
            // whacky design from OpenAPI side. this init converts the generic argument from the Permissions type
            contextPermissions = JSONSchema.CoreContext<Format>.Permissions(permissions)
        } else {
            contextPermissions = internalProperty(name: "_permissions", on: mirror)
        }

        return JSONSchema.CoreContext(
            format: context.format,
            required: modify(property: CoreContext.required, considering: modifications) ?? context.required,
            nullable: modify(property: CoreContext.nullable, considering: modifications) ?? internalProperty(name: "_nullable", on: mirror),
            permissions: contextPermissions,
            deprecated: modify(property: CoreContext.deprecated, considering: modifications) ?? internalProperty(name: "_deprecated", on: mirror),
            title: modify(property: CoreContext.title, considering: modifications) ?? context.title,
            description: modify(property: CoreContext.description, considering: modifications) ?? context.description,
            discriminator: modify(property: CoreContext.discriminator, considering: modifications) ?? context.discriminator,
            externalDocs: modify(property: CoreContext.externalDocs, considering: modifications) ?? context.externalDocs,
            allowedValues: modify(property: CoreContext.allowedValues, considering: modifications) ?? context.allowedValues,
            defaultValue: modify(property: CoreContext.defaultValue, considering: modifications) ?? context.defaultValue,
            example: modify(property: CoreContext.example, considering: modifications) ?? context.example
        )
    }

    private func modifyNumericContext(_ context: JSONSchema.NumericContext, considering modifications: Modifications) -> JSONSchema.NumericContext {
        let minimumBound = modify(property: NumericContext.maximum, considering: modifications) ?? context.maximum
        let maximumBound = modify(property: NumericContext.minimum, considering: modifications) ?? context.minimum

        let minimum: (Double, exclusive: Bool)?
        let maximum: (Double, exclusive: Bool)?

        if let minimumBound = minimumBound {
            minimum = (minimumBound.value, exclusive: minimumBound.exclusive)
        } else {
            minimum = nil
        }

        if let maximumBound = maximumBound {
            maximum = (maximumBound.value, exclusive: maximumBound.exclusive)
        } else {
            maximum = nil
        }

        return JSONSchema.NumericContext(
            multipleOf: modify(property: NumericContext.multipleOf, considering: modifications) ?? context.multipleOf,
            maximum: maximum,
            minimum: minimum
        )
    }

    private func modifyIntegerContext(_ context: JSONSchema.IntegerContext, considering modifications: Modifications) -> JSONSchema.IntegerContext {
        let minimumBound = modify(property: IntegerContext.maximum, considering: modifications) ?? context.maximum
        let maximumBound = modify(property: IntegerContext.minimum, considering: modifications) ?? context.minimum

        let minimum: (Int, exclusive: Bool)?
        let maximum: (Int, exclusive: Bool)?

        if let minimumBound = minimumBound {
            minimum = (minimumBound.value, exclusive: minimumBound.exclusive)
        } else {
            minimum = nil
        }

        if let maximumBound = maximumBound {
            maximum = (maximumBound.value, exclusive: maximumBound.exclusive)
        } else {
            maximum = nil
        }

        return JSONSchema.IntegerContext(
            multipleOf: modify(property: IntegerContext.multipleOf, considering: modifications) ?? context.multipleOf,
            maximum: maximum,
            minimum: minimum
        )
    }

    private func modifyStringContext(_ context: JSONSchema.StringContext, considering modifications: Modifications) -> JSONSchema.StringContext {
        let mirror = Mirror(reflecting: context)

        return JSONSchema.StringContext(
            maxLength: modify(property: StringContext.maxLength, considering: modifications) ?? context.maxLength,
            minLength: modify(property: StringContext.minLength, considering: modifications) ?? internalProperty(name: "_minLength", on: mirror),
            pattern: modify(property: StringContext.pattern, considering: modifications) ?? context.pattern
        )
    }

    private func modifyObjectContext(_ context: JSONSchema.ObjectContext, considering modifications: Modifications) -> JSONSchema.ObjectContext {
        let mirror = Mirror(reflecting: context)

        return JSONSchema.ObjectContext(
            properties: modify(property: ObjectContext.properties, considering: modifications) ?? context.properties,
            additionalProperties: modify(property: ObjectContext.additionalProperties, considering: modifications) ?? context.additionalProperties,
            maxProperties: modify(property: ObjectContext.maxProperties, considering: modifications) ?? context.maxProperties,
            minProperties: modify(property: ObjectContext.minProperties, considering: modifications)
                ?? internalProperty(name: "_minProperties", on: mirror)
        )
    }

    private func modifyArrayContext(_ context: JSONSchema.ArrayContext, considering modifications: Modifications) -> JSONSchema.ArrayContext {
        let mirror = Mirror(reflecting: context)

        return JSONSchema.ArrayContext(
            items: modify(property: ArrayContext.items, considering: modifications) ?? context.items,
            maxItems: modify(property: ArrayContext.maxItems, considering: modifications) ?? context.maxItems,
            minItems: modify(property: ArrayContext.minItems, considering: modifications) ?? internalProperty(name: "_minItems", on: mirror),
            uniqueItems: modify(property: ArrayContext.uniqueItems, considering: modifications) ?? internalProperty(name: "_uniqueItems", on: mirror)
        )
    }

    private func modify<Description: JSONContextDescription>(
        property: Description,
        considering modifications: Modifications
    ) -> Description.PropertyType? {
        guard let modification = modifications[property.key] else {
            return nil
        }

        guard let value = modification.anyValue as? Description.PropertyType else {
            fatalError("""
                       Modification for \(property.key) provided value of type \(type(of: modification.anyValue)). \
                       Expected \(Description.PropertyType.self)
                       """)
        }

        return value
    }

    private func internalProperty<Type>(name: String, on mirror: Mirror) -> Type {
        guard let (_, value) = mirror.children.first(where: { $0.label == name }) else {
            fatalError("Did not find property '\(name)' on Mirror with properties \(mirror.children.compactMap { $0.label }.joined(separator: ", "))")
        }

        guard let casted = value as? Type else {
            fatalError("Failed to cast reflective accessed property \(name) of type \(type(of: value)) to type \(Type.self)")
        }

        return casted
    }
}
