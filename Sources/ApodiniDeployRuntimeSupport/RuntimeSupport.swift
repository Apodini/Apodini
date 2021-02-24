//
//  DeploymentProviderRuntimeSupport.swift
//  
//
//  Created by Lukas Kollmer on 2021-01-01.
//

import Foundation
import Apodini
import NIO
@_exported import ApodiniDeployBuildSupport



public enum RemoteHandlerInvocationRequestResponse<Response: Decodable> {
    // url should be just scheme+hostname+port (but no path)
    case invokeDefault(url: URL)
    case result(EventLoopFuture<Response>)
}


public protocol DeploymentProviderRuntimeSupport: class {
    static var deploymentProviderId: DeploymentProviderID { get }
    
    init(deployedSystem: DeployedSystem, currentNodeId: DeployedSystem.Node.ID) throws
    
    var deployedSystem: DeployedSystem { get }
    var currentNodeId: DeployedSystem.Node.ID { get }
    
    func configure(_ app: Apodini.Application) throws
    
    /// This function is called when a handler uses the remote handler invocation API to invoke another
    /// handler and the remote handler invocation manager has determined that the invocation's target handler is not in the current node.
    /// The deployment provider is given the option to manually implement and realise the remote invocation.
    /// It can also re-delegate this responsibility back to the caller.
    func handleRemoteHandlerInvocation<H: InvocableHandler>(
        _ invocation: HandlerInvocation<H>
    ) throws -> RemoteHandlerInvocationRequestResponse<H.Response.Content>
}


extension DeploymentProviderRuntimeSupport {
    public var deploymentProviderId: DeploymentProviderID {
        Self.deploymentProviderId
    }
}
