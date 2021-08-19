//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini

public enum DeploymentOptionNamespace {}

public typealias DeploymentOptionKey<T: PropertyOption> = PropertyOptionKey<DeploymentOptionNamespace, T>
public typealias DeploymentOption = AnyPropertyOption<DeploymentOptionNamespace>

public typealias DeploymentOptionsContextKey = OptionBasedMetadataContextKey<DeploymentOptionNamespace>
