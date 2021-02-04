//
//  Created by Nityananda on 11.12.20.
//

import Runtime

public struct PropertyInfo: Equatable, Hashable {
    public let name: String
    public let offset: Int
    
    public init(name: String, offset: Int) {
        self.name = name
        self.offset = offset
    }
}

public struct EnrichedInfo {
    public enum Cardinality: Equatable, Hashable {
        case zeroToOne
        case exactlyOne
        case zeroToMany(CollectionContext)
    }

    public enum CollectionContext: Equatable, Hashable {
        case array
        indirect case dictionary(key: EnrichedInfo, value: EnrichedInfo)
    }

    public let typeInfo: TypeInfo
    public let propertyInfo: PropertyInfo?

    public var cardinality: Cardinality
    
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

public extension EnrichedInfo {
    static func node(_ type: Any.Type) throws -> Node<EnrichedInfo> {
        let typeInfo = try Runtime.typeInfo(of: type)
        let root = EnrichedInfo(
            typeInfo: typeInfo,
            propertyInfo: nil
        )

        return Node(root: root) { info in
            info.typeInfo.properties
                .enumerated()
                .compactMap { offset, propertyInfo in
                    do {
                        let typeInfo = try Runtime.typeInfo(of: propertyInfo.type)
                        return EnrichedInfo(
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

// MARK: - EnrichedInfo: Hashable

extension EnrichedInfo: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(typeInfo.name)
        hasher.combine(propertyInfo)
        hasher.combine(cardinality)
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

