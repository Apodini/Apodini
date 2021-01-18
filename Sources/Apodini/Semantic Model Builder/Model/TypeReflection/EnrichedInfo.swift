//
//  Created by Nityananda on 11.12.20.
//

@_implementationOnly import Runtime

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
    let propertiesOffset: Int?

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
            propertiesOffset: nil,
            cardinality: cardinality
        )

        return Node(root: root) { info in
            info.typeInfo.properties
                .enumerated()
                .compactMap { offset, propertyInfo in
                    do {
                        let traveler = try travelThroughWrappers(propertyInfo.type)
                        let typeInfo = try Runtime.typeInfo(of: traveler.type)
                        let cardinality = traveler.wrappers.first ?? .exactlyOne
                        
                        return EnrichedInfo(
                            typeInfo: typeInfo,
                            propertyInfo: propertyInfo,
                            propertiesOffset: offset + 1,
                            cardinality: cardinality
                        )
                    } catch {
                        let errorDescription = String(describing: error)
                        let keyword = "Runtime.Kind.opaque"

                        guard !errorDescription.contains(keyword) else {
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
            && lhs.propertyInfo?.name == rhs.propertyInfo?.name
            && lhs.propertiesOffset == rhs.propertiesOffset
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

private func travelThroughWrappers(
    _ type: Any.Type
) throws -> (type: Any.Type, wrappers: [EnrichedInfo.Cardinality]) {
    if isOptional(type) {
        let wrappedType = try Runtime.typeInfo(of: type).genericTypes[0]
        let next = try travelThroughWrappers(wrappedType)
        return (next.type, [.zeroToOne] + next.wrappers)
    } else {
        return (type, [])
    }
}
