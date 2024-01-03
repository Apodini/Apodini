//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

#if DEBUG || RELEASE_TESTING
import Foundation
@testable import Apodini

/// A `SharedRepository` which only provides access to the `contents` provided on initialization or values
/// that have previously been placed on the shared repository.
public class MockSharedRepository: SharedRepository {
    private var content: [ObjectIdentifier: any KnowledgeSource]
    
    public init(_ contents: (any KnowledgeSource.Type, any KnowledgeSource)...) {
        var storage = [ObjectIdentifier: any KnowledgeSource]()
        for content in contents {
            storage[ObjectIdentifier(content.0)] = content.1
        }
        self.content = storage
    }
    
    public subscript<S>(_ type: S.Type) -> S where S: KnowledgeSource {
        get {
            content[ObjectIdentifier(type)]! as! S
        }
        set {
            content[ObjectIdentifier(type)] = newValue
        }
    }
    
    public func request<S>(_ type: S.Type) throws -> S where S: KnowledgeSource {
        self[type]
    }
}

public extension RelationshipWebServiceModel {
    /// Create a `RelationshipWebServiceModel` providing access to an empty global `SharedRepository`
    convenience init(mockSharedRepository: any SharedRepository = MockSharedRepository()) {
        self.init(mockSharedRepository)
    }
}
#endif
