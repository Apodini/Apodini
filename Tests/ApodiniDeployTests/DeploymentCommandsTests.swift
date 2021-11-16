//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import XCTApodini
import ApodiniUtils


class DeploymentCommandsTests: ApodiniDeployTestCase {
    private func executionTask(with args: [String]) throws -> ChildProcess {
        ChildProcess(
            executableUrl: Self.apodiniDeployTestWebServiceTargetUrl,
            arguments: args,
            workingDirectory: Self.productsDirectory,
            captureOutput: true,
            redirectStderrToStdout: true,
            launchInCurrentProcessGroup: false
        )
    }
    
    func testDeployCommand() throws {
        let errMsg = "Calling this command directly is not supported."
        
        let task = try executionTask(with: [
            "deploy"
        ])
        
        let info = try task.launchSync()
        let output = try task.whitespacesAndNewlineAdjustedStdout()
        XCTAssertTrue(info.exitCode == EXIT_FAILURE, "ChildProcess should not succeed")
        XCTAssertTrue(output.contains(errMsg), "Found wrong error message.")
    }
    
    func testLocalhostCommands() throws {
        let expectedExportCommandAbstract = "OVERVIEW: Export web service structure - Localhost"
        let exportTask = try executionTask(with: [
            "deploy",
            "export-ws-structure",
            "local",
            "--help"
        ])
        var info = try exportTask.launchSync()
        var output = try exportTask.whitespacesAndNewlineAdjustedStdout()
        XCTAssertTrue(info.exitCode == EXIT_SUCCESS, "ExportTask failed. Found exitCode \(info.exitCode)")
        XCTAssertTrue(output.contains(expectedExportCommandAbstract), "Expected help message \n\(expectedExportCommandAbstract)\n but found \n\(output)")
        
        let expectedStartupCommandAbstract = "OVERVIEW: Start a web service - Localhost"
        let startupTask = try executionTask(with: [
            "deploy",
            "startup",
            "local",
            "--help"
        ])
        info = try startupTask.launchSync()
        output = try startupTask.whitespacesAndNewlineAdjustedStdout()
        XCTAssertTrue(info.exitCode == EXIT_SUCCESS, "StartupTask failed. Found exitCode \(info.exitCode)")
        XCTAssertTrue(output.contains(expectedStartupCommandAbstract), "Expected help message \n\(expectedStartupCommandAbstract)\n but found \n\(output)")
    }
    
    func testAWSCommands() throws {
        let expectedExportCommandAbstract = "OVERVIEW: Export web service structure - AWS"
        let exportTask = try executionTask(with: [
            "deploy",
            "export-ws-structure",
            "aws",
            "--help"
        ])
        var info = try exportTask.launchSync()
        var output = try exportTask.whitespacesAndNewlineAdjustedStdout()
        XCTAssertTrue(info.exitCode == EXIT_SUCCESS, "ExportTask failed. Found exitCode \(info.exitCode)")
        XCTAssertTrue(output.contains(expectedExportCommandAbstract), "Expected help message \n\(expectedExportCommandAbstract)\n but found \n\(output)")
        
        let expectedStartupCommandAbstract = "OVERVIEW: Start a web service - AWS Lambda"
        let startupTask = try executionTask(with: [
            "deploy",
            "startup",
            "aws-lambda",
            "--help"
        ])
        info = try startupTask.launchSync()
        output = try startupTask.whitespacesAndNewlineAdjustedStdout()
        XCTAssertTrue(info.exitCode == EXIT_SUCCESS, "StartupTask failed. Found exitCode \(info.exitCode)")
        XCTAssertTrue(output.contains(expectedStartupCommandAbstract), "Expected help message \n\(expectedStartupCommandAbstract)\n but found \n\(output)")
    }
    
    func testConfigurationWithSingleCommand() throws {
        let task = ChildProcess(
            executableUrl: Self.apodiniDeployTestWebServiceTargetUrl,
            arguments: [
                "dummy"
            ],
            workingDirectory: Self.productsDirectory,
            captureOutput: true,
            redirectStderrToStdout: true,
            launchInCurrentProcessGroup: false
        )
        let info = try task.launchSync()
        let output = try task.readStdoutToEnd()
        XCTAssertTrue(info.exitCode == EXIT_SUCCESS, "ChildProcess failed")
        XCTAssertEqual(output.trimmingCharacters(in: .whitespacesAndNewlines), "DummyParsableCommand")
    }
    
    func testConfigurationWithSubCommands() throws {
        let task = ChildProcess(
            executableUrl: Self.apodiniDeployTestWebServiceTargetUrl,
            arguments: [
                "mainCommand",
                "subCommand"
            ],
            workingDirectory: Self.productsDirectory,
            captureOutput: true,
            redirectStderrToStdout: true,
            launchInCurrentProcessGroup: false
        )
        let info = try task.launchSync()
        let output = try task.readStdoutToEnd()
        XCTAssertTrue(info.exitCode == EXIT_SUCCESS, "ChildProcess failed")
        XCTAssertEqual(output.trimmingCharacters(in: .whitespacesAndNewlines), "DummySubCommand")
    }
    
    func testConfigurationWithoutSubCommand() throws {
        let task = ChildProcess(
            executableUrl: Self.apodiniDeployTestWebServiceTargetUrl,
            arguments: [
                "mainCommand"
            ],
            workingDirectory: Self.productsDirectory,
            captureOutput: true,
            redirectStderrToStdout: true,
            launchInCurrentProcessGroup: false
        )
        let info = try task.launchSync()
        let output = try task.readStdoutToEnd()
        XCTAssertTrue(info.exitCode == EXIT_SUCCESS, "ChildProcess failed")
        XCTAssertEqual(output.trimmingCharacters(in: .whitespacesAndNewlines), "DummyParsableCommandWithSubCommands")
    }
}

fileprivate extension ChildProcess {
    func whitespacesAndNewlineAdjustedStdout() throws -> String {
        try self.readStdoutToEnd().trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
