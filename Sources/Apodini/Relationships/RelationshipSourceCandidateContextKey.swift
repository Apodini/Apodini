//
// Created by Andreas Bauer on 20.12.20.
//


public struct RelationshipSourceCandidateContextKey: ContextKey {
    public typealias Value = [PartialRelationshipSourceCandidate]
    public static let defaultValue: Value = []

    public static func reduce(value: inout [PartialRelationshipSourceCandidate], nextValue: () -> [PartialRelationshipSourceCandidate]) {
        value.append(contentsOf: nextValue())
    }
}
