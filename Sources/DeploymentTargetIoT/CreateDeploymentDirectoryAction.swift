import Foundation
import DeviceDiscovery
import NIO
import Logging
import ApodiniUtils

/// A simple `PostDiscoveryAction` to create the deployment directory on the raspberry pi
struct CreateDeploymentDirectoryAction: PostDiscoveryAction {
    @Configuration(IoTContext.deploymentDirectory)
    var deploymentDir: URL

    static var identifier = ActionIdentifier(rawValue: "createDeploymentDir")

    func run(_ device: Device, on eventLoopGroup: EventLoopGroup, client: SSHClient?) throws -> EventLoopFuture<Int> {
        try client?.bootstrap()
        try client?.fileManager.createDir(on: deploymentDir, permissions: 777, force: false)
        return eventLoopGroup.next().makeSucceededFuture(0)
    }
}
