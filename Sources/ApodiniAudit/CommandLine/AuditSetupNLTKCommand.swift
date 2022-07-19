//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini
import ArgumentParser
import ApodiniUtils

// MARK: - AuditSetupCommand
struct AuditSetupNLTKCommand<Service: WebService>: AuditParsableSubcommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "setup-nltk",
            abstract: "Install nltk via pip and download the wordnet and omw-1.4 corpora",
            discussion: "",
            version: "0.1.0"
        )
    }
    
    @OptionGroup
    var webService: Service
    
    func run(app: Application) throws {
        defer {
            app.shutdown()
        }
        
        // Install nltk
        let pipArgs = ["install", "--user", "-U", "nltk"]
        var (exitCode, output) = try runCommand("pip", pipArgs)
        
        if exitCode != 0 {
            print("Failed to install nltk. Aborting. Output: \(output)")
            return
        }
        
        print("Successfully installed nltk!")
        
        // Install wordnet, omw-1.4, and averaged_perceptron_tagger corpora
        let pythonArgs = ["-m", "nltk.downloader", "wordnet", "omw-1.4", "averaged_perceptron_tagger"]
        (exitCode, output) = try runCommand("python", pythonArgs)
        
        if exitCode != 0 {
            print("Failed to install corpora. Aborting. Output: \(output)")
            return
        }
        
        print("Successfully installed wordnet, omw-1.4, and averaged_perceptron_tagger corpora!")
    }
    
    private func executableURL(for executable: String) -> URL? {
        ChildProcess.findExecutable(
            named: executable,
            additionalSearchPaths: ["/usr/local/bin/", "/opt/homebrew/bin/"]
        )
    }
    
    private func runCommand(_ executable: String, _ arguments: [String]) throws -> (exitCode: Int32, output: String) {
        guard let executableURL = executableURL(for: executable) else {
            throw ExecutableNotFound.notFound(executable)
        }
        
        let childProcess = ChildProcess(
            executableUrl: executableURL,
            arguments: arguments,
            workingDirectory: nil,
            captureOutput: true,
            redirectStderrToStdout: true,
            launchInCurrentProcessGroup: false,
            environment: [:],
            inheritsParentEnvironment: true
        )
        let terminationInfo = try childProcess.launchSync()
        return (terminationInfo.exitCode, try childProcess.readStdoutToEnd())
    }
}

enum ExecutableNotFound: Error, CustomStringConvertible {
    case notFound(_ exec: String)
    
    public var description: String {
        switch self {
        case .notFound(let exec):
            return "Could not find executable \(exec)"
        }
    }
}
