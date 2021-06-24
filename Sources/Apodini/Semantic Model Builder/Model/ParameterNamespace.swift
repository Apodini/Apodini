//
// Created by Andreas Bauer on 06.01.21.
//

import Foundation

public struct ParameterNamespace: OptionSet {
    public let rawValue: UInt8

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    public static let lightweight = ParameterNamespace(rawValue: 1 << 0)
    public static let content = ParameterNamespace(rawValue: 1 << 1)
    public static let path = ParameterNamespace(rawValue: 1 << 2)

    fileprivate static let all: ParameterNamespace = [.lightweight, .content, .path]
}

extension ParameterNamespace: CustomStringConvertible {
    public var description: String {
        var types: [ParameterType] = []

        if (rawValue & 1) > 0 {
            types.append(.lightweight)
        }
        if (rawValue & 2) > 0 {
            types.append(.content)
        }
        if (rawValue & 4) > 0 {
            types.append(.path)
        }

        return types.description
    }
}

// MARK: Common ParameterNamespace Definitions
public extension Array where Element == ParameterNamespace {
    /// With the `.global` level, a parameter name must be
    /// unique across all `ParameterType`s on the given `Endpoint`.
    /// This is the default namespace when nothing is specified by the exporter.
    static let global: [ParameterNamespace] = [.all]
    /// With the `.individual` level, a parameter name must be
    /// unique across all parameters with the same `ParameterTyp` on the given `Endpoint`.
    static let individual: [ParameterNamespace] = [.lightweight, .content, .path]
}

extension ParameterNamespace {
    func contains(type: ParameterType) -> Bool {
        switch type {
        case .lightweight:
            return contains(.lightweight)
        case .path:
            return contains(.path)
        case .content:
            return contains(.content)
        }
    }
}


// MARK: Parameter Name Collision
extension AnyEndpoint {
    /// Internal method which kicks off the parameter namespace collision checks
    func parameterNameCollisionCheck(in namespaces: [ParameterNamespace]) {
        self[EndpointParameters.self].nameCollisionCheck(on: self, in: namespaces)
    }

    /// Internal method which kicks off the parameter namespace collision checks
    func parameterNameCollisionCheck(in namespaces: ParameterNamespace...) {
        self[EndpointParameters.self].nameCollisionCheck(on: self, in: namespaces)
    }
}

private extension Array where Element == AnyEndpointParameter {
    func nameCollisionCheck(on endpoint: AnyEndpoint, in namespaces: [ParameterNamespace]) {
        let namespaces = namespaces
        if namespaces.isEmpty {
            fatalError("Parameter name collision check was run with empty namespace definition!")
        }

        for namespace in namespaces {
            let result = self.reduce(
                into: (
                    // we use Set here instead of an array with linear search, as the array approach would have O(n^2) complexity
                    // worst case of hashing is O(n), which would result in O(n^2) with our loop over the self array
                    set: Set<String>(minimumCapacity: count),
                    // In order to deliver a useful error messages, we collect the names
                    // for which name collisions occurred in the set below
                    collisions: Set<String>()
                )
            ) { result, parameter in
                if namespace.contains(type: parameter.parameterType) {
                    let count = result.set.count
                    result.set.insert(parameter.name)

                    if result.set.count == count { // count didn't change => no new element inserted => name collision
                        result.collisions.insert(parameter.name)
                    }
                }
            }

            if !result.collisions.isEmpty {
                #warning("Replace by unified parsing error")
                fatalError("Found colliding parameter names \(result.collisions) on Handler '\(endpoint.description)' in namespace \(namespace.description)!")
            }
        }
    }
}
