//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//       

import Foundation
import ArgumentParser
import DeviceDiscovery

/// A Command that kills running tmux session on the given devices.
/// This can be used to stop instances of a deployed web services without having to manually ssh into each deployment target.
public struct KillSessionCommand: ParsableCommand {
    public static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "kill-session",
            abstract: "IoT deployment - Stop Session",
            discussion: "Kills the running deployed system on the remote device.",
            version: "0.4.0"
        )
    }
    
    @Argument(help: "The type ids that should be searched for")
    var types: String
    
    @Option(help: "Name of the deployed web service")
    var productName: String

    public func run() throws {
        print("test")
        for id in types.split(separator: ",").map(String.init) {
            let discovery = DeviceDiscovery(DeviceIdentifier(id))
            discovery.configuration = [.runPostActions: false]

            let (username, password) = IoTContext.readUsernameAndPassword(id)
            let results = try discovery.run(2).wait()

            for result in results {
                let ipAddress = try IoTContext.ipAddress(for: result.device)
                let client = try SSHClient(username: username, password: password, ipAdress: ipAddress)
                IoTContext.logger.info("Trying to kill session on \(ipAddress)")
                try client.execute(cmd: "tmux kill-session -t \(productName)")
            }
            IoTContext.logger.info("Finished.")
        }
    }
    
    public init() {}
}
