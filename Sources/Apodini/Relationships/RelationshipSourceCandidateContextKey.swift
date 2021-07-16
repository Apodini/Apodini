//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

public struct RelationshipSourceCandidateContextKey: ContextKey {
    public typealias Value = [PartialRelationshipSourceCandidate]
    public static let defaultValue: [PartialRelationshipSourceCandidate] = []
}
