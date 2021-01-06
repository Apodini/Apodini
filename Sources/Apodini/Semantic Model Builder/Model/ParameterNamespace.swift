//
// Created by Andi on 06.01.21.
//

import Foundation

/// Anything conforming to this protocol represents a definition of a `EndpointParameter` namespace.
protocol ParameterNamespace: CustomStringConvertible {
    /// Used to determine if the given `AnyEndpointParameter` is part of the given namespace.
    func includes(parameter: AnyEndpointParameter) -> Bool
}

/// This enum provides some easy to use definitions for parameter namespaces commonly used.
enum DefaultParameterNamespace {
    /// With the `.global` level, a parameter name must be
    /// unique across all `ParameterType`s on the given `Endpoint`.
    case global
    /// With the `.individual` level, a parameter name must be
    /// unique across all parameters with the same `ParameterTyp` on the given `Endpoint`.
    /// This is the default namespace when nothing is specified by the exporter.
    case individual

    var namespace: [ParameterNamespace] {
        switch self {
        case .global:
            return [[.lightweight, .content, .path]]
        case .individual:
            return [ParameterType.lightweight, ParameterType.content, ParameterType.path]
        }
    }
}


extension ParameterType: ParameterNamespace {
    // A Parameter itself can also be a `ParameterNameSpace`.
    // But using something like [.path] is shorten and thus nicer to use, probably.
    func includes(parameter: AnyEndpointParameter) -> Bool {
        parameter.parameterType == self
    }
}

extension ParameterType: CustomStringConvertible {
    var description: String {
        switch self {
        case .lightweight:
            return "lightweight"
        case .content:
            return "content"
        case .path:
            return "path"
        }
    }
}

extension Array: ParameterNamespace where Element == ParameterType {
    func includes(parameter: AnyEndpointParameter) -> Bool {
        self.contains(parameter.parameterType)
    }
}


extension Array where Element == AnyEndpointParameter {
    func nameCollisionCheck<H: Handler>(on handler: H.Type = H.self, in namespaces: [ParameterNamespace]) {
        var namespaces = namespaces
        if namespaces.isEmpty {
            namespaces = DefaultParameterNamespace.individual.namespace
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
                if namespace.includes(parameter: parameter) {
                    let count = result.set.count
                    result.set.insert(parameter.name)

                    if result.set.count == count { // count didn't change => no new element inserted => name collisions
                        result.collisions.insert(parameter.name)
                    }
                }
            }

            if !result.collisions.isEmpty {
                #warning("Replace by unified parsing error")
                fatalError("Found colliding parameter names \(result.collisions) on Handler '\(handler)' in namespace \(namespace.description)!")
            }
        }
    }
}
