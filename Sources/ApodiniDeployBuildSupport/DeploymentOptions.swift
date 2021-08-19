//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini

/// The option namespace for ApodiniDeploy options.
public enum DeploymentOptionNamespace {}

/// Typealias for deployment option `PropertyOptionKey`.
public typealias DeploymentOptionKey<T: PropertyOption> = PropertyOptionKey<DeploymentOptionNamespace, T>
/// Typealias for a deployment `AnyPropertyOption`
public typealias DeploymentOption = AnyPropertyOption<DeploymentOptionNamespace>

/// The `ContextKey` for all deployment options.
public typealias DeploymentOptionsContextKey = OptionBasedMetadataContextKey<DeploymentOptionNamespace>
