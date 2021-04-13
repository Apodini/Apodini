//
//  File.swift
//
//
//  Created by Eldi Cano on 30.03.21.
//

import Foundation

/// Contains predefined shell command cases
public enum ShellCommand {
    /// Used for killing the specified port
    case killPort(Int)

    var method: String {
        switch self {
        case let .killPort(port): return "kill $(lsof -ti:\(port))"
        }
    }
}

/// A helper function to run custom shell commands, e.g. on app launch
public func runShellCommand(_ command: ShellCommand) {
    shell(command.method)
}

@discardableResult
private func shell(_ command: String) -> String {
    let task = Process()
    let pipe = Pipe()

    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", command]
    task.executableURL = URL(string: "/bin/zsh")
    do {
        try task.run()
    } catch {
        return ""
    }
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()

    return String(data: data, encoding: .utf8) ?? ""
}
