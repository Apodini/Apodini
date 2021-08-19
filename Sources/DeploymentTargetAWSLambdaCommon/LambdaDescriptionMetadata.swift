//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import ApodiniDeployBuildSupport

public struct LambdaDescriptionOption: PropertyOption, RawRepresentable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static func & (lhs: LambdaDescriptionOption, rhs: LambdaDescriptionOption) -> LambdaDescriptionOption {
        fatalError("Conflicting lambda descriptions specified ('\(lhs.rawValue)' vs '\(rhs.rawValue)').")
    }
}

public extension PropertyOptionKey where PropertyNameSpace == DeploymentOptionNamespace, Option == LambdaDescriptionOption {
    static let lambdaDescription = DeploymentOptionKey<LambdaDescriptionOption>()
}


public extension ComponentMetadataNamespace {
    typealias LambdaDescription = LambdaDescriptionMetadata
}

public struct LambdaDescriptionMetadata: ComponentMetadataDefinition {
    public typealias Key = DeploymentOptionsContextKey

    public let value: PropertyOptionSet<DeploymentOptionNamespace>

    public init(_ description: String) {
        self.value = .init()
    }
}
