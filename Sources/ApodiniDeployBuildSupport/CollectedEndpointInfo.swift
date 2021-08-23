//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import Apodini
import ApodiniUtils


/// Well-known environment variables, i.e. environment variables which are read by Apodini and used when performing certain tasks.
/// Note: environment variables which are used in a lambda context must satisfy the regex `[a-zA-Z]([a-zA-Z0-9_])+`
public enum WellKnownEnvironmentVariables {
    /// Key for an environment variable specifying the current instance's node id (relative to the whole deployed system).
    /// This environment variable is only set of the web service is running as part of a managed deployment.
    public static let currentNodeId = "AD_CURRENT_NODE_ID"
    
    /// Key for an environment variable specifying the execution mode of ApodiniDeploy, ether dump the WebService's model structure or launch the WebService with custom config
    public static let executionMode = "AD_EXECUTION_MODE"
    
    /// Key for an environment variable specifying the url of the directory used for ApodiniDeploy, either the outputURL or configURL
    public static let fileUrl = "AD_INPUT_FILE_PATH"
}

// swiftlint:disable type_name
/// Possible values of the well-known environment variable `WellKnownEnvironmentVariables.executionMode`
public enum WellKnownEnvironmentVariableExecutionMode {
    /// Value of an environment variable to tell Apodini to write the web service's structure to disk.
    /// In the support framework so that we can share this constant between Apodini (which needs to check for it)
    /// and the deployment provider (which needs to pass it to the invocation).
    public static let exportWebServiceModelStructure = "exportWebServiceModelStructure"
    
    /// Value of an environment variable to tell an Apodini server that it's being launched with a custom config
    public static let launchWebServiceInstanceWithCustomConfig = "launchWebServiceInstanceWithCustomConfig"
}


public struct ExporterIdentifier: RawRepresentable, Codable, Hashable, Equatable {
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

public struct ExportedEndpoint: Codable, Hashable, Equatable {
    public let handlerType: HandlerTypeIdentifier
    /// Identifier of the  handler this endpoint was generated for
    public let handlerId: AnyHandlerIdentifier
    public private(set) var userInfo: Data?

    public init(handlerType: HandlerTypeIdentifier, handlerId: AnyHandlerIdentifier, data: Data?) {
        self.handlerType = handlerType
        self.handlerId = handlerId
        self.userInfo = data
    }

    public init(handlerType: HandlerTypeIdentifier, handlerId: AnyHandlerIdentifier) {
        self.init(handlerType: handlerType, handlerId: handlerId, data: nil)
    }
    
    public init<T: Encodable>(handlerType: HandlerTypeIdentifier, handlerId: AnyHandlerIdentifier, userInfo: T) throws {
        self.handlerType = handlerType
        self.handlerId = handlerId
        try setUserInfo(userInfo)
    }

    public mutating func setUserInfo<T: Encodable>(_ value: T?) throws {
        self.userInfo = try value.map { try $0.encodeToJSON() }
    }

    public func readUserInfo<T: Decodable>(as _: T.Type) throws -> T? {
        try userInfo.flatMap { try T(decodingJSON: $0) }
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.handlerId)
    }
    
    public static func == (lhs: ExportedEndpoint, rhs: ExportedEndpoint) -> Bool {
        lhs.handlerId == rhs.handlerId
    }
}

/// The information collected about an `Endpoint`.
/// - Note: This type's `Hashable`  implementation ignores deployment options.
/// - Note: This type's `Equatable` implementation ignores all context of the endpoint other than its identifier,
///         and will only work if all deployment options of both objects being compared are reducible.
public struct CollectedEndpointInfo: Hashable {
    public let handlerType: HandlerTypeIdentifier
    public let endpoint: AnyEndpoint
    public let deploymentOptions: PropertyOptionSet<DeploymentOptionNamespace>
    
    public init(
        handlerType: HandlerTypeIdentifier,
        endpoint: AnyEndpoint,
        deploymentOptions: PropertyOptionSet<DeploymentOptionNamespace> = .init()
    ) {
        self.handlerType = handlerType
        self.endpoint = endpoint
        self.deploymentOptions = deploymentOptions
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(endpoint[AnyHandlerIdentifier.self])
    }

    public static func == (lhs: CollectedEndpointInfo, rhs: CollectedEndpointInfo) -> Bool {
        lhs.handlerType == rhs.handlerType
            && lhs.endpoint[AnyHandlerIdentifier.self] == rhs.endpoint[AnyHandlerIdentifier.self]
    }
}
