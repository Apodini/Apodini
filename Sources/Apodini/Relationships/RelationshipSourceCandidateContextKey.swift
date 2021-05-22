//
// Created by Andreas Bauer on 20.12.20.
//

// TODO "Relationships" Metadata Group


public struct RelationshipSourceCandidateContextKey: ContextKey { // TODO move into own file
    public typealias Value = [PartialRelationshipSourceCandidate]
    public static let defaultValue: Value = []

    public static func reduce(value: inout [PartialRelationshipSourceCandidate], nextValue: () -> [PartialRelationshipSourceCandidate]) {
        value.append(contentsOf: nextValue())
    }
}
