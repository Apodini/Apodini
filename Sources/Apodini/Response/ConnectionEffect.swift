//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
/// A `ConnectionEffect` describes the affect of a `Response` on a connection.
/// This impacts stream connection types such as client, service or bidirectional streams
///
///
/// These values should not be directly set by an Apodini developer.
/// Use the possible `Response` static computed properties or functions to create a `Response`
public enum ConnectionEffect {
    /// The connection should stay open
    case open
    /// The connection should be closed
    case close
}
