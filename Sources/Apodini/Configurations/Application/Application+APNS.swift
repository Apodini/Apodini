//
//  Application+APNS.swift
//  
//
//  Created by Tim Gymnich on 23.12.20.
//

import APNS
import Logging
import NIO
import Foundation
@_implementationOnly import AsyncKit


extension Application {
    /// Holds the APNS Configuration
    public var apns: APNS {
        .init(application: self)
    }

    /// Holds the APNS Configuration
    public struct APNS {
        struct ConfigurationKey: StorageKey {
            // swiftlint:disable nesting
            typealias Value = APNSwiftConfiguration
        }

        /// APNS Configuration
        public var configuration: APNSwiftConfiguration? {
            get {
                self.application.storage[ConfigurationKey.self]
            }
            nonmutating set {
                self.application.storage[ConfigurationKey.self] = newValue
            }
        }

        struct PoolKey: StorageKey, LockKey {
            typealias Value = EventLoopGroupConnectionPool<APNSConnectionSource>
        }

        internal var pool: EventLoopGroupConnectionPool<APNSConnectionSource> {
            if let existing = self.application.storage[PoolKey.self] {
                return existing
            } else {
                let lock = self.application.locks.lock(for: PoolKey.self)
                lock.lock()
                defer { lock.unlock() }
                guard let configuration = self.configuration else {
                    fatalError("APNS not configured. Use app.apns.configuration = ...")
                }
                let new = EventLoopGroupConnectionPool(
                    source: APNSConnectionSource(configuration: configuration),
                    maxConnectionsPerEventLoop: 1,
                    logger: self.application.logger,
                    on: self.application.eventLoopGroup
                )
                self.application.storage.set(PoolKey.self, to: new) {
                    $0.shutdown()
                }
                return new
            }
        }

        let application: Application
    }
}

extension Application.APNS: APNSwiftClient {
    public var logger: Logger? {
        self.application.logger
    }

    public var eventLoop: EventLoop {
        self.application.eventLoopGroup.next()
    }

    public func send(
        rawBytes payload: ByteBuffer,
        pushType: APNSwiftConnection.PushType,
        to deviceToken: String,
        expiration: Date?,
        priority: Int?,
        collapseIdentifier: String?,
        topic: String?,
        logger: Logger?
    ) -> EventLoopFuture<Void> {
        self.application.apns.pool.withConnection(
            logger: logger,
            on: self.eventLoop
        ) {
            $0.send(
                rawBytes: payload,
                pushType: pushType,
                to: deviceToken,
                expiration: expiration,
                priority: priority,
                collapseIdentifier: collapseIdentifier,
                topic: topic,
                logger: logger
            )
        }
    }
}

internal final class APNSConnectionSource: ConnectionPoolSource {
    private let configuration: APNSwiftConfiguration

    public init(configuration: APNSwiftConfiguration) {
        self.configuration = configuration
    }
    public func makeConnection(
        logger: Logger,
        on eventLoop: EventLoop
    ) -> EventLoopFuture<APNSwiftConnection> {
        APNSwiftConnection.connect(configuration: self.configuration, on: eventLoop)
    }
}
