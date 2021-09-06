//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//       

import Foundation
import DeviceDiscovery
import ApodiniUtils
import Logging

enum IoTContext {
    static let deploymentDirectory = ConfigurationProperty("key_deployDir")
    
    static let defaultUsername = "ubuntu"
    static let defaultPassword = "test1234"
    
    static let logger = Logger(label: "de.apodini.IoTDeployment")

    static let dockerVolumeTmpDir = URL(fileURLWithPath: "/app/tmp")

    private static var startDate = Date()

    static func copyResources(_ device: Device, origin: String, destination: String) throws {
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
    
    static func ipAddress(for device: Device) throws -> String {
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
    static func runTaskOnRemote(
        _ command: String,
        workingDir: String,
        device: Device,
        assertSuccess: Bool = true,
        responseHandler: ((String) -> Void)? = nil
    ) throws {
        let client = try getSSHClient(for: device)
        let cmd = "cd \(workingDir) && \(command)"
        if assertSuccess {
            client.executeWithAssertion(cmd: cmd, responseHandler: responseHandler)
        } else {
            let _: Bool = try client.execute(cmd: cmd, responseHandler: nil)
        }
    }
    
    static func startTimer() {
        startDate = Date()
    }
    
    static func endTimer() {
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: startDate, to: Date())
        guard let hours = components.hour,
              let minutes = components.minute,
              let seconds = components.second else {
                  Self.logger.error("Unable to read timer")
                  return
              }
        let hourString = hours < 10 ? "0\(hours)" : "\(hours)"
        let minuteString = minutes < 10 ? "0\(minutes)" : "\(minutes)"
        let secondsString = seconds < 10 ? "0\(seconds)" : "\(seconds)"
        logger.notice("Complete deployment in \(hourString):\(minuteString):\(secondsString)")
    }
    
    static func readUsernameAndPassword(for reason: String) -> (String, String) {
        Self.logger.info("The username for \(reason) :")
        var username = readLine()
        while username.isEmpty {
            username = readLine()
        }
        Self.logger.info("The password for \(reason) :")
        let passw = getpass("")
        return (username!, String(cString: passw!))
    }

    static func runInDocker(
        imageName: String,
        command: String,
        device: Device,
        workingDir: URL,
        containerName: String = "",
        detached: Bool = false,
        privileged: Bool = false,
        volumeDir: URL = dockerVolumeTmpDir,
        port: Int = 8080) throws {
        var arguments: String {
            var args = [
                "sudo",
                "docker",
                "run",
                "--rm",
                "--name",
                containerName,
                "-p",
                "\(port):\(port)",
                detached ? "-d" : "",
                privileged ? "--privileged": "",
                "-v",
                "\(workingDir.path):\(volumeDir.path):Z",
                imageName,
                command
            ]
            return args.joined(separator: " ")
        }
        print(arguments)
        try runTaskOnRemote(arguments, workingDir: workingDir.path, device: device)
    }
}

struct IoTDeploymentError: Swift.Error {
    let description: String
}

extension Dictionary {
    static func + (lhs: [Key: Value], rhs: [Key: Value]) -> [Key: Value] {
        lhs.merging(rhs) { $1 }
    }
}
