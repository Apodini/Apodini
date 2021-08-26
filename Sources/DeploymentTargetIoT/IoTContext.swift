import Foundation
import DeviceDiscovery
import ApodiniUtils

public enum IoTContext {
    static let resourceDirectory = ConfigurationProperty("key_resourceDir")
    static let deploymentDirectory = ConfigurationProperty("key_deployDir")
    static let logger = ConfigurationProperty("key_logger")
    
    static let defaultUsername = "ubuntu"
    static let defaultPassword = "test1234"

    public static func copyResources(_ device: Device, origin: String, destination: String) throws {
        let task = Task(executableUrl: Self._findExecutable("rsync"),
                        arguments: [
                            "-avz",
                            "-e",
                            "'ssh'",
                            origin,
                            destination
                        ],
                        workingDirectory: nil,
                        launchInCurrentProcessGroup: true)
        try task.launchSyncAndAssertSuccess()
    }

    public static func rsyncHostname(_ device: Device, path: String) -> String {
        "\(device.username)@\(device.ipv4Address!):\(path)"
    }
    
    public static func ipAddress(for device: Device) throws -> String {
        guard let ipaddress = device.ipv4Address else {
            throw IoTDeploymentError(description: "Unable to get ipaddress for \(device)")
        }
        return ipaddress
    }

    private static func _findExecutable(_ name: String) -> URL {
        guard let url = Task.findExecutable(named: name) else {
            fatalError("Unable to find executable '\(name)'")
        }
        return url
    }
    
    private static func getSSHClient(for device: Device) throws -> SSHClient {
        guard let anyDevice = device as? AnyDevice, let ipAddress = anyDevice.ipv4Address else {
            throw IoTDeploymentError(description: "Failed to get sshclient for \(device)")
        }
        return try SSHClient(username: anyDevice.username, password: anyDevice.password, ipAdress: ipAddress)
    }
    
    /// A wrapper function that navigates to the specified working directory and executes the command remotely
    public static func runTaskOnRemote(_ command: String, workingDir: String, device: Device, assertSuccess: Bool = true, responseHandler: ((String) -> Void)? = nil) throws {
        let client = try getSSHClient(for: device)
        let cmd = "cd \(workingDir) && \(command)"
        if assertSuccess {
            client.executeWithAssertion(cmd: cmd, responseHandler: responseHandler)
        } else {
            let _: Bool = try client.execute(cmd: cmd, responseHandler: nil)
        }
    }
}

public struct IoTDeploymentError: Swift.Error {
    public let description: String
    
    public init(description: String) {
        self.description = description
    }
}

extension Dictionary {
    static func +(lhs: [Key: Value], rhs: [Key: Value]) -> [Key: Value] {
        lhs.merging(rhs) { $1 }
    }
}
