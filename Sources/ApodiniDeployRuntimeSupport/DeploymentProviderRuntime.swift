//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              
import ArgumentParser
import Foundation
import Apodini
import ApodiniUtils
import NIO
@_exported import ApodiniDeployBuildSupport


/// How a remote handler invocation should be processed.
public enum RemoteHandlerInvocationRequestResponse<Response: Decodable> {
    /// The remote handler invocation should be realised using the internal direct invocation API,
    /// by sending a message to the specified url
    /// - Note: The url should be just scheme+hostname+port (but no path)
    case invokeDefault(url: URL)
    /// The remote handler invocation was handled by the deployment provider..
    /// The associated value here is a future which will resolve to the invoked handler's response.
    case result(EventLoopFuture<Response>)
}


/// The protocol used to define a deployment provider's runtime support type.
///
/// The runtime support type's responsibility is to integrate the deployment provider into the running web service.
/// This is done by allowing the runtime support type to hook into the lifecycle of the web service, at the following events:
/// 1. When the system is initialised. This is when the runtime is also being initialised.
/// 2. When the system is being configured.
///   This is when the runtime's `configure(_ app:)` function will be called, giving it an opportunity
///   to perform custom configuration on the `Apodini.Application` object
/// 3. When the remote handler invocation API was used to invoke a handler, and the dispatcher determined that the handler
///   should be invoked remotely (i.e. not in the current process).
///   In this case the runtime is given the option to simply forward the invocation to some url, or implement and perform the invocation manually.
public protocol DeploymentProviderRuntime: AnyObject {
    /// The unique identifier of the deployment provider this runtime belongs to.
    /// - Note: This property is used to locate the correct runtime based on the deployment provider
    ///         used to create the deployment, so it has to match the corresponding CLI's `identifier` exactly.
    static var identifier: DeploymentProviderID { get }
    
    init(deployedSystem: DeployedSystem, currentNodeId: DeployedSystemNode.ID) throws
    
    var deployedSystem: DeployedSystem { get }
    var currentNodeId: DeployedSystemNode.ID { get }
    
    static var exportCommand: ParsableCommand.Type { get }
    
    func configure(_ app: Apodini.Application) throws
    
    /// This function is called when a handler uses the remote handler invocation API to invoke another
    /// handler and the remote handler invocation manager has determined that the invocation's target handler is not in the current node.
    /// The deployment provider is given the option to manually implement and realise the remote invocation.
    /// It can also re-delegate this responsibility back to the caller.
    func handleRemoteHandlerInvocation<H: InvocableHandler>(
        _ invocation: HandlerInvocation<H>
    ) throws -> RemoteHandlerInvocationRequestResponse<H.Response.Content>
}


extension DeploymentProviderRuntime {
    /// The identifier of the deployment provider
    public var identifier: DeploymentProviderID {
        Self.identifier
    }
}

public struct DeploymentMemoryStorage: MemoryStorage {
    public static var current = DeploymentMemoryStorage()
    
    private var object: StructureExporter?
    
    public mutating func store(_ object: StructureExporter) {
        self.object = object
    }
    
    public func retrieve() -> StructureExporter? {
        object
    }
}
