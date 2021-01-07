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
        case zeroToMany
    }

    let typeInfo: TypeInfo
    let propertyInfo: PropertyInfo?
    let propertiesOffset: Int?

    var cardinality: Cardinality = .exactlyOne
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
