import Foundation
import DeviceDiscovery
import NIO
import Logging
import ApodiniUtils

/// A Default implementation of a `PostDiscoveryAction`. It looks for connected LIFX smart lamps using NIOLIFX.
struct LIFXDeviceDiscoveryAction: PostDiscoveryAction {
    @Configuration(IoTUtilities.resourceDirectory)
    var resourceURL: URL

    @Configuration(.username)
    var username: String

    @Configuration(IoTUtilities.deploymentDirectory)
    var deploymentDir: URL

    @Configuration(IoTUtilities.logger)
    var logger: Logger

    static var identifier: ActionIdentifier {
        ActionIdentifier("LIFX")
    }

    private var tmpLifxDir: URL {
        deploymentDir.appendingPathComponent("tmp_lifx", isDirectory: true)
    }

    private let setupScriptFilename = "setup-script"
    private let resultsFilename = "lifx_devices"

    func run(_ device: Device, on eventLoopGroup: EventLoopGroup, client: SSHClient?) throws -> EventLoopFuture<Int> {
        let eventLoop = eventLoopGroup.next()
        guard let sshClient = client else {
            return eventLoop.makeFailedFuture(
                IoTDeploymentError(
                    description: "Could not find ssh client. Check if you provided the necessary credentials in the config."
                )
            )
        }
        // Need to manually bootstrap the client, since we dont want to pass open connections around
        try sshClient.bootstrap()

        // Check if the setup script is in the res dir
        let scriptFileUrl = resourceURL.appendingPathComponent(setupScriptFilename)
        guard FileManager.default.fileExists(atPath: scriptFileUrl.path) else {
            throw IoTDeploymentError(description: "Unable to find '\(setupScriptFilename)' resource in bundle")
        }

        // Create tmp sub dir in deployment dir for results
        try sshClient.fileManager.createDir(on: tmpLifxDir, permissions: 777)

        try IoTUtilities.copyResourcesToRemote(
            device,
            origin: scriptFileUrl.path,
            destination: IoTUtilities.rsyncHostname(device, path: tmpLifxDir.path)
        )

        logger.info("executing script")
        try IoTUtilities.runTaskOnRemote(
            "bash \(tmpLifxDir.appendingPathComponent(setupScriptFilename)) \(tmpLifxDir.path)",
            workingDir: tmpLifxDir.path,
            device: device
        )

        logger.info("copying json back")
        let remoteResultsPath = tmpLifxDir.appendingPathComponent(resultsFilename)
        
        try IoTUtilities.copyResourcesToRemote(
            device,
            origin: IoTUtilities.rsyncHostname(device, path: remoteResultsPath.path),
            destination: resourceURL.path
        )

        let resultsPath = resourceURL.appendingPathComponent(resultsFilename).path
        guard let data = FileManager.default.contents(atPath: resultsPath) else {
            throw IoTDeploymentError(description: "Could not find results file at \(scriptFileUrl)")
        }
        let foundDevices = try JSONDecoder().decode([CodableDevice].self, from: data)

        // Delete resource file local and remote dir after we read its data
        try FileManager.default.removeItem(atPath: resultsPath)
        logger.info("removed search result")
        sshClient.fileManager.remove(at: tmpLifxDir, isDir: true)
        logger.info("removed tmp search dir")

        return eventLoop.makeSucceededFuture(foundDevices.count)
    }

    init() {}
}

/// Create the identical struct as in NIOLIFX_Impl to be able to decode the json correctly.
/// Since the implementation of NIOLIFX is cloned and run locally on the device, we don't import it and therefore have no access to the structs.
struct CodableDevice: Codable {
    let address: UInt64
    let location: CodableLocation
    let group: CodableGroup
}

struct CodableLocation: Codable {
    let id: String
    let label: String
    let updatedAt: UInt64

    enum CodingKeys: String, CodingKey {
        case id, label, updatedAt
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try values.decode(String.self, forKey: .id)
        self.label = try values.decode(String.self, forKey: .label)
        self.updatedAt = try values.decode(UInt64.self, forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(id, forKey: .id)
        try values.encode(label, forKey: .label)
        try values.encode(updatedAt, forKey: .updatedAt)
    }
}

struct CodableGroup: Codable {
    let id: String
    let label: String
    let updatedAt: UInt64

    enum CodingKeys: String, CodingKey {
        case id, label, updatedAt
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try values.decode(String.self, forKey: .id)
        self.label = try values.decode(String.self, forKey: .label)
        self.updatedAt = try values.decode(UInt64.self, forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(id, forKey: .id)
        try values.encode(label, forKey: .label)
        try values.encode(updatedAt, forKey: .updatedAt)
    }
}
