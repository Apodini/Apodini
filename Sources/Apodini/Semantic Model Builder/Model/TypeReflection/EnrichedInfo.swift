//
//  Created by Nityananda on 11.12.20.
//

@_implementationOnly import Runtime

enum TypeReflectionDidEncounterRecursion {}

struct PropertyInfo: Equatable, Hashable {
    let name: String
    let offset: Int
}

struct EnrichedInfo {
    enum Cardinality {
        case zeroToOne
        case exactlyOne
        case zeroToMany(CollectionContext)
    }

    enum CollectionContext {
        case array
        indirect case dictionary(key: EnrichedInfo, value: EnrichedInfo)
    }

    let typeInfo: TypeInfo
    let propertyInfo: PropertyInfo?

    var cardinality: Cardinality = .exactlyOne
}

extension EnrichedInfo {
    static func node(_ type: Any.Type) throws -> Node<EnrichedInfo> {
        let traveler = try travelThroughWrappers(type)
        let typeInfo = try Runtime.typeInfo(of: traveler.type)
        let cardinality = traveler.wrappers.first ?? .exactlyOne
        
        let root = EnrichedInfo(
            typeInfo: typeInfo,
            propertyInfo: nil,
            cardinality: cardinality
        )

        var didEncounterArray = false
        var visitedCompositeTypes: Set = [ObjectIdentifier(typeInfo.type)]
        
        return Node(root: root) { info in
            info.typeInfo.properties
                .enumerated()
                .compactMap { offset, propertyInfo in
                    do {
                        let traveler = try travelThroughWrappers(propertyInfo.type)
                        if traveler.wrappers.contains(.zeroToMany(.array)) {
                            didEncounterArray = true
                        }
                        var typeInfo = try Runtime.typeInfo(of: traveler.type)
                        
                        if didEncounterArray {
                            if visitedCompositeTypes.contains(.init(
                                TypeReflectionDidEncounterRecursion.self
                            )) {
                                typeInfo = try Runtime.typeInfo(of: TypeReflectionDidEncounterRecursion.self)
                            } else {
                                let identifier = ObjectIdentifier(typeInfo.type)
                                if visitedCompositeTypes.contains(identifier) {
                                    visitedCompositeTypes.insert(.init(
                                        TypeReflectionDidEncounterRecursion.self
                                    ))
                                } else {
                                    if !isSupportedScalarType(typeInfo.type) {
                                        visitedCompositeTypes.insert(identifier)
                                    }
                                }
                            }
                        }
                        let cardinality = traveler.wrappers.first ?? .exactlyOne
                        
                        return EnrichedInfo(
                            typeInfo: typeInfo,
                            propertyInfo: .init(
                                name: propertyInfo.name,
                                offset: offset + 1
                            ),
                            cardinality: cardinality
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

// MARK: - EnrichedInfo: Equatable

extension EnrichedInfo: Equatable {
    public static func == (lhs: EnrichedInfo, rhs: EnrichedInfo) -> Bool {
        lhs.typeInfo.type == rhs.typeInfo.type
            && lhs.propertyInfo == rhs.propertyInfo
            && lhs.cardinality == rhs.cardinality
    }
}

extension EnrichedInfo.Cardinality: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.zeroToOne, .zeroToOne), (.exactlyOne, .exactlyOne):
            return true
        case let (.zeroToMany(lhsCollection), .zeroToMany(rhsCollection)):
            return (lhsCollection) == (rhsCollection)
        default:
            return false
        }
    }
}

extension EnrichedInfo.CollectionContext: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.array, .array):
            return true
        case let (.dictionary(lhsKey, lhsValue), .dictionary(rhsKey, rhsValue)):
            return (lhsKey, lhsValue) == (rhsKey, rhsValue)
        default:
            return false
        }
    }
}

// MARK: - Traveler

private typealias Traveler = (type: Any.Type, wrappers: [EnrichedInfo.Cardinality])

private func travelThroughWrappers(_ type: Any.Type) throws -> Traveler {
    if isOptional(type) {
        let wrappedType = try Runtime.typeInfo(of: type).genericTypes[0]
        let next = try travelThroughWrappers(wrappedType)
        return (next.type, [.zeroToOne] + next.wrappers)
        
    } else if mangledName(of: type) == "Array" {
        let elementType = try Runtime.typeInfo(of: type).genericTypes[0]
        let next = try travelThroughWrappers(elementType)
        return (next.type, [.zeroToMany(.array)] + next.wrappers)
        
    } else {
        return (type, [])
    }
}
