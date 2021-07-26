//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

/// '_functionBuilder' to build `PathComponent`s
@resultBuilder
public enum PathComponentBuilder {
    /// Return any array of `PathComponent`s directly
    public static func buildBlock(_ paths: PathComponent...) -> [PathComponent] {
        paths
    }
}
