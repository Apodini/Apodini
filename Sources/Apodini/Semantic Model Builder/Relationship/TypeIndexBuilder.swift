//
// Created by Andreas Bauer on 16.01.21.
//

import Foundation
import Logging
@_implementationOnly import Runtime

/// Represents the result of the building process of the `TypeIndexBuilder`
struct TypeIndexBuilderResult: CustomDebugStringConvertible {
    let typeIndex: TypeIndexStorage
    let sourceCandidates: CollectedRelationshipCandidates

    var debugDescription: String {
        """
        TypeIndexBuilderResult(\
        typeIndex: \(
            typeIndex
                .map { key, entry in "{\(entry.type),\(key.operation)} => " + entry.debugDescription }
                .joined(separator: ", ")
        ), \
        sourceCandidates: \(
            sourceCandidates
                .map {reference, candidates in
                    reference.debugDescription + " => \(candidates.map { $0.debugDescription }.joined(separator: ", "))"
                }
                .joined(separator: ",")
        )\
        )
        """
    }
}

/// The `TypeIndexBuilder` is used to index Handlers by their return type information (conforming to `Content`).
/// It is needed to build Relationship information around type information (see Relationship.md proposal).
struct TypeIndexBuilder: CustomDebugStringConvertible {
    var debugDescription: String {
        typeIndex.values.map { value in value.debugDescription }.joined(separator: ", ")
    }

    var logger: Logger
    fileprivate var typeIndex: [ObjectIdentifier: CapturedTypeIndex] = [:]

    init(logger: Logger) {
        self.logger = logger
    }

    mutating func indexContentType(
        content: Encodable.Type,
        reference: EndpointReference,
        markedDefault: Bool,
        pathParameters: [AnyEndpointPathParameter],
        operation: Operation) {
        let identifier = ObjectIdentifier(content)

        if let info = try? typeInfo(of: content),
           info.kind == .class || info.kind == .struct || info.kind == .enum {
            let capture = ParsedTypeIndexEntryCapture(reference, type: content, markedDefault: markedDefault, pathParameters: pathParameters)

            var index = typeIndex[identifier, default: CapturedTypeIndex()]
            index.indexContentType(of: content, operation: operation, capture: capture)

            typeIndex[identifier] = index
        }
    }
}

/// This struct represents a preliminary TypeIndex (for a specific type) which is used
/// to store any capture type data while parsing the Syntax Tree.
private struct CapturedTypeIndex: CustomDebugStringConvertible {
    var debugDescription: String {
        "{\(entries.map { operation, entry in "\(operation) => \(entry.debugDescription)" }.joined(separator: ", "))}"
    }

    private var entries: [Operation: ParsedTypeIndexEntry] = [:]

    mutating func indexContentType(of type: Any.Type, operation: Operation, capture: ParsedTypeIndexEntryCapture) {
        var entry = entries[operation, default: ParsedTypeIndexEntry(type: type, operation: operation)]

        entry.add(capture)

        entries[operation] = entry
    }
}

/// This struct represents the indexed handlers for a given type and operation
private struct ParsedTypeIndexEntry: CustomDebugStringConvertible {
    let type: Any.Type
    let operation: Operation


    /// Holds all captured `Handler`s returning the defined `type`, index by their location (path).
    /// Handlers under the same path are grouped together into one capture.
    var captured: [[EndpointPath]: ParsedTypeIndexEntryCapture] = [:]


    /// Used to count the use of `.defaultReference` on `Handler`s defined under different paths.
    /// We store the different References to provide proper descriptions in error messages
    var handlersMarkedDefault: [EndpointReference] = []
    var markedDefaultCount: Int {
        handlersMarkedDefault.count
    }
    /// Counts the maximal amount of path parameter on one of the captured `Handler`s.
    /// Having this count makes it easy for use to identify which captures are sources
    /// and which is the destination.
    var maxCapturedParameterCount: Int = 0
    /// Counts how many `Handler`s handlers have a count of path parameters
    /// equal to `maxCapturedParameterCount`, but are located under a different path.
    var equalParameterCount: Int = 0

    var debugDescription: String {
        let string = captured.values
            .map { value in
                value.debugDescription
            }
            .joined(separator: ", ")
        return "[\(type)(\(captured.count)): " + string + "]"
    }


    init(type: Any.Type, operation: Operation) {
        self.type = type
        self.operation = operation
    }

    mutating func add(_ capture: ParsedTypeIndexEntryCapture) {
        let absolutePath = capture.reference.absolutePath

        guard captured[absolutePath] == nil else {
            // ParsedTypeIndexEntry is indexed by `Content.Type` and `Operation`.
            // As we properly verified that there are no colliding `Operations` under the same path
            // (we have, as we assume that `addEndpoint(...)` was called first, otherwise we couldn't call .reference()),
            // something has gone horribly wrong
            fatalError("""
                       Reached a point where we encountered a Operation conflict (under the same path), \
                       but the Operation collision check should have already been called!
                       """)
        }

        captured[absolutePath] = capture

        if capture.markedDefault {
            handlersMarkedDefault.append(capture.reference)
        }

        if capture.pathParameters.count == maxCapturedParameterCount {
            equalParameterCount += 1
        }

        if capture.pathParameters.count > maxCapturedParameterCount {
            equalParameterCount = 1 // ensure the equal count is reset properly
            maxCapturedParameterCount = capture.pathParameters.count
        }
    }
}

struct ParsedTypeIndexEntryCapture: CustomDebugStringConvertible {
    var debugDescription: String {
        reference.debugDescription + "[params:\(pathParameters.count),\(markedDefault)]"
    }

    let reference: EndpointReference
    /// The returned `Content` type of the reference `Endpoint`
    let type: Any.Type
    let markedDefault: Bool
    let pathParameters: [AnyEndpointPathParameter]

    init(_ reference: EndpointReference, type: Any.Type, markedDefault: Bool, pathParameters: [AnyEndpointPathParameter]) {
        self.reference = reference
        self.type = type
        self.markedDefault = markedDefault
        self.pathParameters = pathParameters
    }
}


// MARK: TypeIndexBuilder Building


extension TypeIndexBuilder {
    /// This method will build the resulting `TypeIndex` and also evaluate candidates
    /// which may be the source for a given Relationship.
    ///
    /// For this step we need to consider the following listed steps:
    ///
    /// 1. Throw away the entry (for a given operation) if there are multiple Handlers
    ///    returning the same type, but located under different paths
    ///    (and none of them is marked with `defaultRelationship`). [Conflict]
    /// 2. Ensure that `.defaultRelationship` is only used once on multiple paths for a given Operation
    /// 3. Handle Handlers located under multiple Path Parameter
    ///   3.1. Detect destinations for a given Operation
    ///   3.2. Detect sources (operation independent). Idea is that Handlers having less path parameter in their path
    ///    (but can provide values for the path parameters of a type with more path parameters) can link to those
    ///    Handlers maintaining more path parameters. (Typical example /authenticatedUser links to /user/{userId})
    ///   3.3. Throw away entry (for a given operation) if there are multiple Handlers returning the same type,
    ///     which have the same max amount of path parameters, are located under different paths
    ///     and are not marked with `.defaultRelationship`. 1. is a special case of 3.3. with max maxCapturedParameterCount=0.
    ///
    /// - Returns: The constructed type index dictionary.
    func build() -> TypeIndexBuilderResult {
        logger.debug("[TypeIndexBuilder] Captured: \(self.debugDescription)")

        var typeIndex: TypeIndexStorage = [:]
        // collect any potential sources for a given type which could link to entries
        var sourceCandidates: [RelationshipSourceCandidate] = []

        for (identifier, capturedIndex) in self.typeIndex {
            for operation in Operation.allCases {
                var entry: TypeIndexEntry? // the resulting entry of the type index (for a given Operation)
                capturedIndex.build(logger: logger, for: operation, entry: &entry, sources: &sourceCandidates)

                if let entry = entry {
                    let identifier = TypeIdentifier(objectId: identifier, operation: operation)
                    precondition(typeIndex[identifier] == nil,
                                 """
                                 Encountered inconsistency were we tried to index \(entry) but the index \
                                 already contained a entry for the TypeIdentifier \(identifier).
                                 """)

                    typeIndex[identifier] = entry
                }
            }
        }

        let result = TypeIndexBuilderResult(
            typeIndex: typeIndex,
            sourceCandidates: sourceCandidates.referenceIndexed()
        )

        logger.debug("[TypeIndexBuilder] Results: \(result.debugDescription)")

        return result
    }
}

extension CapturedTypeIndex {
    func build(logger: Logger, for operation: Operation, entry: inout TypeIndexEntry?, sources: inout [RelationshipSourceCandidate]) {
        if let parsedEntry = entries[operation] {
            parsedEntry.build(logger: logger, entry: &entry, sources: &sources)
        }
    }
}

extension ParsedTypeIndexEntry {
    /// This method is uses raw captured data to build the final TypeIndexEntry and collect potential Relationship sources.
    func build(logger: Logger, entry: inout TypeIndexEntry?, sources: inout [RelationshipSourceCandidate]) {
        if markedDefaultCount > 1 {
            // Illegal use of `.defaultRelationship`
            fatalError("""
                           The `.defaultRelationship` modifier was used multiple times \
                           for type \(type):\(operation) on \(handlersMarkedDefault.map { $0.debugDescription }.joined(separator: ", "))!
                           """)
        } else if markedDefaultCount == 1 {
            let captures = captured.values.filter { capture in capture.markedDefault }
            precondition(captures.count == 1, """
                                             Encountered inconsistency in capture data of the TypeIndexBuilder. \
                                             Counted only one `markedDefault` capture but encountered \(captures.count): \(debugDescription).
                                             """)

            let capturedEntry = captures.first! // swiftlint:disable:this force_unwrapping
            entry = capturedEntry.build()

            for capture in captured.values where capture.pathParameters.count < capturedEntry.pathParameters.count {
                // everything which lives above the (single) destination is a possible candidate for a relationship source
                sources.append(capture.asSource())
            }
        } else if markedDefaultCount == 0 {
            if equalParameterCount > 1 {
                // We can't select ONE Handler representing the return type as there are multiple Handlers
                // returning the same type and none were marked with `.defaultRelationship`
                logger.debug("""
                             [TypeIndexBuilder] Encountered type \(type) with ambiguity, as multiple Handlers return that type \
                             and none of them is marked with `.defaultRelationship` modifier.
                             """)
                return
            }

            var found = false // used for consistency checking

            for capture in captured.values {
                if capture.pathParameters.count == maxCapturedParameterCount {
                    precondition(!found, """
                                         Encountered inconsistency in capture data of the TypeIndexBuilder. Counted only one Handler \
                                         having maximum of \(maxCapturedParameterCount) path parameters but encountered multiple: \(debugDescription).
                                         """)

                    entry = capture.build()
                    found = true
                } else {
                    // everything which is not the (single) destination is a possible candidate for a relationship source
                    sources.append(capture.asSource())
                }
            }
        } else {
            fatalError("Encountered negative count for signed int `markedDefaultCount`")
        }
    }
}

extension ParsedTypeIndexEntryCapture {
    func build() -> TypeIndexEntry {
        TypeIndexEntry(type: type, reference: reference, pathParameters: pathParameters)
    }
}
