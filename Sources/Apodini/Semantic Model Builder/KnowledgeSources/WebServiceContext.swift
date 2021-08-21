//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

/// ``KnowledgeSource`` giving access to the ``Context`` of the ``WebService``.
public struct WebServiceContext: KnowledgeSource {
    let context: Context

    init (_ context: Context) {
        self.context = context
    }

    public init<B: Blackboard>(_ blackboard: B) throws {
        self.init(blackboard[Application.self].webServiceContext)
    }
}

public extension WebServiceModel {
    /// The ``Context`` of the ``WebService``. This particularly gives access to all
    /// Metadata Declarations made on the ``WebService``.
    var context: Context {
        self[WebServiceContext.self].context
    }
}

// MARK: Application+WebServiceContext

private struct WebServiceContextKey: StorageKey {
    typealias Value = Context
}

extension Application {
    var webServiceContext: Context {
        get {
            guard let context = storage[WebServiceContextKey.self] else {
                fatalError("Tried accessing web service context before it was stored!")
            }
            return context
        }
        set {
            storage[WebServiceContextKey.self] = newValue
        }
    }
}
