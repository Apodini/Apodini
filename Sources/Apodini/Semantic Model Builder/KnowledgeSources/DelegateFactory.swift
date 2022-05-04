//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

public struct DelegateFactoryBasis<H: Handler>: KnowledgeSource {
    public let delegate: Delegate<H>
    
    public init<B>(_ sharedRepository: B) throws where B: SharedRepository {
        self.delegate = Delegate(sharedRepository[EndpointSource<H>.self].handler, .required)
    }
}

/// A ``DelegateFactory`` allows for creating ``instance()``s of a ``Delegate``
/// suitable for usage in an ``InterfaceExporter``.
public class DelegateFactory<H: Handler, I: InterfaceExporter>: KnowledgeSource {
    private let sharedRepository: SharedRepository
    
    private lazy var delegate: Delegate<H> = sharedRepository[DelegateFactoryBasis<H>.self].delegate
    
    public required init<B>(_ sharedRepository: B) throws where B: SharedRepository {
        self.sharedRepository = sharedRepository
    }
    
    /// Creates one instance of the ``Delegate``.
    ///
    /// - Note: Use a new instance for each client-connection! Otherwise data may be shared between
    /// all clients using the same instance.
    public func instance() -> Delegate<H> {
        var delegate = self.delegate
        delegate.activate()
        delegate.environment(
            \ExporterTypeObserveMetadata.value,
            ExporterTypeObserveMetadata.ExporterTypeObserveMetadata(
                exporterType: I.self,
                parameterNamespace: I.parameterNamespace
             )
        )
        return delegate
    }
}
