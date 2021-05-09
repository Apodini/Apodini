//
//  Shell.swift
//
//
//  Created by Eldi Cano on 30.03.21.
//

import Foundation


/// Contains predefined shell command cases
public enum ShellCommand {
    /// Used for killing the specified port
    case killPort(Int)
    case getProcessesAtPort(Int)

    var method: String {
        switch self {
        case let .killPort(port): return "kill $(lsof -ti:\(port))"
        case let .getProcessesAtPort(port): return "lsof -ti:\(port)"
        }
    }
}

/// A helper function to run custom shell commands, e.g. on app launch
@discardableResult
public func runShellCommand(_ command: ShellCommand) -> String {
    shell(command.method)
}

@discardableResult
private func shell(_ command: String) -> String {
    let task = Process()
    let pipe = Pipe()

    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", command]
    task.executableURL = URL(fileURLWithPath: "/bin/zsh")
    do {
        try task.run()
    } catch {
        return ""
    }
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()

    return String(data: data, encoding: .utf8) ?? ""
}
