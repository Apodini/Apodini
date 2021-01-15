//
//  File.swift
//
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

    var typeInfo: TypeInfo
    let propertyInfo: PropertyInfo?
    let propertiesOffset: Int?

    var cardinality: Cardinality = .exactlyOne
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

extension EnrichedInfo: Equatable {
    public static func == (lhs: EnrichedInfo, rhs: EnrichedInfo) -> Bool {
        if lhs.typeInfo.mangledName != rhs.typeInfo.mangledName {
            return false
        }
        if lhs.propertyInfo?.name != rhs.propertyInfo?.name {
            return false
        }
        if lhs.propertiesOffset != rhs.propertiesOffset {
            return false
        }
        if lhs.cardinality != rhs.cardinality {
            return false
        }
        return true
    }
}

extension EnrichedInfo {
    static func node(_ type: Any.Type) throws -> Node<EnrichedInfo> {
        let typeInfo = try Runtime.typeInfo(of: type)
        let root = EnrichedInfo(
            typeInfo: typeInfo,
            propertyInfo: nil,
            propertiesOffset: nil)

        return Node(root: root) { info in
            info.typeInfo.properties
                .enumerated()
                .compactMap { offset, propertyInfo in
                    do {
                        let typeInfo = try Runtime.typeInfo(of: propertyInfo.type)
                        return EnrichedInfo(
                            typeInfo: typeInfo,
                            propertyInfo: propertyInfo,
                            propertiesOffset: offset + 1
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
