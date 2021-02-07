//
//  DeploymentProviderRuntimeSupport.swift
//  
//
//  Created by Lukas Kollmer on 2021-01-01.
//

import Foundation
import Apodini
import ApodiniVaporSupport
import NIO
@_exported import ApodiniDeployBuildSupport



public enum RemoteHandlerInvocationRequestResponse<Response: Decodable> {
    // url should be just scheme+hostname+port (but no path)
    case invokeDefault(url: URL)
    case result(EventLoopFuture<Response>)
}


public protocol DeploymentProviderRuntimeSupport: class {
    static var deploymentProviderId: DeploymentProviderID { get }
    
    init(deployedSystem: DeployedSystemStructure, currentNodeId: DeployedSystemStructure.Node.ID) throws
    
    var deployedSystem: DeployedSystemStructure { get }
    var currentNodeId: DeployedSystemStructure.Node.ID { get }
    
    
    func configure(_ app: Apodini.Application) throws
    
    /// This function is called when a handler uses the remote handler invocation API to invoke another
    /// handler and the remote handler invocation manager has determined that the invocation's target handler is not in the current node.
    /// The deployment provider is given the option to manually implement and realise the remote invocation.
    /// It can also re-delegate this responsibility back to the caller.
    /// - Note: ideally we'd constrain this to `H: InvocableHandler`,
    ///     but that doesn't work since the `InvocableHandler` protocol is defined in the ApodiniDeploy target,
    ///     which has a depencency on the current target, meaning that we can't access the type here.
    ///     Not that this should matter much, since the function which calls this function _does_ have a `: InvocableHandler` constraint.
    func handleRemoteHandlerInvocation<H: IdentifiableHandler>( // TODO rename requestRemoteHandlerInvocation?
        _ invocation: HandlerInvocation<H>
    ) throws -> RemoteHandlerInvocationRequestResponse<H.Response.Content>
}


extension DeploymentProviderRuntimeSupport {
    public var deploymentProviderId: DeploymentProviderID {
        Self.deploymentProviderId
    }
}
