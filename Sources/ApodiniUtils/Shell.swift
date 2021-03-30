//
//  File.swift
//
//
//  Created by Eldi Cano on 30.03.21.
//

import Foundation

public enum ShellCommand {
    case killPort(Int)

    var method: String {
        switch self {
        case let .killPort(port): return "kill $(lsof -ti:\(port))"
        }
    }
}

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
    task.launchPath = "/bin/zsh"
    task.launch()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()

    return String(data: data, encoding: .utf8) ?? ""
}
