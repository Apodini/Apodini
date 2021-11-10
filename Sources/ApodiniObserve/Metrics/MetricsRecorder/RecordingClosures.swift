//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Logging

/// Namespace for the metrics recording closures
public enum RecordingClosures<Key: Hashable, Value> {
    /// The closure type of a closure which is executed before the handler is processed
    public typealias Before = (ObserveMetadata.Value, Logger.Metadata, inout [Key: Value]) -> Void
    /// The closure type of a closure which is executed after the handler is processed (also in case of an exception)
    public typealias After = (ObserveMetadata.Value, Logger.Metadata, [Key: Value]) -> Void
    /// The closure type of a closure which is executed if the handler throws an exception
    public typealias AfterException = (ObserveMetadata.Value, Logger.Metadata, Error, [Key: Value]) -> Void
}
