//
//  Application+APNS.swift
//
//
//  Created by Tim Gymnich on 23.12.20.
//

import Apodini
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

    // swiftlint:disable function_parameter_count
    /**
     APNSwiftConnection send method. Sends a notification to the desired deviceToken.
     - Parameter payload: the alert to send.
     - Parameter pushType: push type of the notification.
     - Parameter deviceToken: device token to send alert to.
     - Parameter encoder: customer JSON encoder if needed.
     - Parameter expiration: a date that the notificaiton expires.
     - Parameter priority: priority to send the notification with.
     - Parameter collapseIdentifier: a collapse identifier to use for grouping notifications
     - Parameter topic: the bundle identifier that this notification belongs to.

     For more information see:
     [Retrieve Your App's Device Token](https://developer.apple.com/documentation/usernotifications/registering_your_app_with_apns#2942135)
     ### Usage Example: ###
     ```
     let apns = APNSwiftConnection.connect()
     let expiry = Date().addingTimeInterval(5)
     try apns.send(notification, pushType: .alert, to: "b27a07be2092c7fbb02ab5f62f3135c615e18acc0ddf39a30ffde34d41665276", with: JSONEncoder(), expiration: expiry, priority: 10, collapseIdentifier: "huro2").wait()
     ```
     */
    public func send(
        rawBytes payload: ByteBuffer,
        pushType: APNSwiftConnection.PushType,
        to deviceToken: String,
        expiration: Date?,
        priority: Int?,
        collapseIdentifier: String?,
        topic: String?,
        logger: Logger?,
        apnsID: UUID? = nil
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
                logger: logger,
                apnsID: apnsID
            )
        }
    }
}

internal final class APNSConnectionSource: ConnectionPoolSource {
    private let configuration: APNSwiftConfiguration

    init(configuration: APNSwiftConfiguration) {
        self.configuration = configuration
    }

    func makeConnection(
        logger: Logger,
        on eventLoop: EventLoop
    ) -> EventLoopFuture<APNSwiftConnection> {
        APNSwiftConnection.connect(configuration: self.configuration, on: eventLoop)
    }
}

