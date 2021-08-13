import Foundation
import DeviceDiscovery
import ApodiniUtils

enum IoTUtilities {
    static let resourceDirectory = ConfigurationProperty("key_resourceDir")
    static let deploymentDirectory = ConfigurationProperty("key_deployDir")
    static let logger = ConfigurationProperty("key_logger")
    
    static let defaultUsername = "pi"
    static let defaultPassword = "rasp_ma-1511"

    static var resourceURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Resources", isDirectory: true)
    }

    static func copyResourcesToRemote(_ device: Device, origin: String, destination: String) throws {
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

    static func rsyncHostname(_ device: Device, path: String) -> String {
        "\(device.username)@\(device.ipv4Address!):\(path)"
    }

    private static func _findExecutable(_ name: String) -> URL {
        guard let url = Task.findExecutable(named: name) else {
            fatalError("Unable to find executable '\(name)'")
        }
        return url
    }
    
    /// Due to Swift nio ssh being asynchronous by default, we don't have a convenient way to execute synchronous calls on remote.
    /// This is why (at least for now) we use Apodini's `Task` to execute single commands synchronously.
    static func runTaskOnRemote(_ command: String, workingDir: String, device: Device, assertSuccess: Bool = true) throws {
        let task = Task(
            executableUrl: Self._findExecutable("ssh"),
            arguments: [
                "\(device.username)@\(device.ipv4Address)",
                ["cd /\(workingDir)", command].joined(separator: " && ")
            ],
            captureOutput: false,
            redirectStderrToStdout: true,
            launchInCurrentProcessGroup: false)
        if assertSuccess {
            try task.launchSyncAndAssertSuccess()
        } else {
            _ = try task.launchSync()
        }
    }
}

public struct IoTDeploymentError: Swift.Error {
    let description: String
}
