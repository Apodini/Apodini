//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
import Apodini
import Runtime

/// `PropertyInfo` models the property/field/member layout in a composite type.
public struct PropertyInfo: Equatable, Hashable {
    public let name: String
    public let offset: Int
    
    public init(name: String, offset: Int) {
        self.name = name
        self.offset = offset
    }
}

/// `ReflectionInfo` is the composite of a type's type info and property info, if it is embedded in
/// a composite type.
public struct ReflectionInfo {
    /// `Cardinality`, i.e., the number of elements in a grouping, as a property of that grouping,
    /// models how many times a value appears for a property.
    public enum Cardinality: Equatable, Hashable {
        case zeroToOne
        case exactlyOne
        case zeroToMany(CollectionContext)
    }
    
    /// `CollectionContext` further models the grouping of values for a property.
    public enum CollectionContext: Equatable, Hashable {
        case array
        indirect case dictionary(key: ReflectionInfo, value: ReflectionInfo)
    }
    
    /// The type info reflecting a type.
    public let typeInfo: TypeInfo
    /// The property info, if the type was embedded in a composite type.
    public let propertyInfo: PropertyInfo?
    /// The cardinality of a property.
    ///
    /// `.exactlyOne` by default.
    public var cardinality: Cardinality
    
    /// Initialize an `ReflectionInfo` instance.
    public init(
        typeInfo: TypeInfo,
        propertyInfo: PropertyInfo?,
        cardinality: Cardinality = .exactlyOne
    ) {
        self.typeInfo = typeInfo
        self.propertyInfo = propertyInfo
        self.cardinality = cardinality
    }
}

public extension ReflectionInfo {
    /// Recursively initialize a `ReflectionInfo` node from a root type.
    /// - Parameter type: The type that should be reflected.
    /// - Throws: A `RuntimeError`, if `Runtime` encounters an error during reflection.
    /// - Returns: A node of values reflecting every type composing the root type.
    static func node(_ type: Any.Type) throws -> Node<ReflectionInfo> {
        let typeInfo = try Runtime.typeInfo(of: type)
        let root = ReflectionInfo(
            typeInfo: typeInfo,
            propertyInfo: nil
        )

        return Node(root: root) { info in
            info.typeInfo.properties
                .enumerated()
                .compactMap { offset, propertyInfo in
                    do {
                        let typeInfo = try Runtime.typeInfo(of: propertyInfo.type)
                        return ReflectionInfo(
                            typeInfo: typeInfo,
                            propertyInfo: .init(
                                name: propertyInfo.name,
                                offset: offset + 1
                            )
                        )
                    } catch {
                        let errorDescription = String(describing: error)
                        let keywords = [
                            "\(Runtime.Kind.opaque)",
                            "\(Runtime.Kind.function)"
                        ]

                        let errorIsKnown = keywords.contains(where: { keyword in
                            errorDescription.contains(keyword)
                        })
                        
                        if errorIsKnown {
                            return nil
                        }
                        
                        preconditionFailure(errorDescription)
                    }
                }
        }
    }
}

// MARK: - ReflectionInfo: Hashable

extension ReflectionInfo: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(typeInfo.name)
        hasher.combine(propertyInfo)
        hasher.combine(cardinality)
    }
}

// MARK: - ReflectionInfo: Equatable

extension ReflectionInfo: Equatable {
    public static func == (lhs: ReflectionInfo, rhs: ReflectionInfo) -> Bool {
        lhs.typeInfo.type == rhs.typeInfo.type
            && lhs.propertyInfo == rhs.propertyInfo
            && lhs.cardinality == rhs.cardinality
    }
}
