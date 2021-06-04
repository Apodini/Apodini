//
// Created by Andreas Bauer on 28.05.21.
//

import Foundation
import XCTest

class XCTBootstrap: XCTestCase {
    func testRunner() throws {
        print("Bootstrapping negative test runner...")
        let runner = try NegativeTestRunner()

        try runner.prepareConfiguration()
        try runner.run()

        runner.evaluateResults()
    }
}

class NegativeTestRunner {
    private let fileManager = FileManager.default
    /// Hold the URL to the root of the SPM project (containing the `Tests` folder).
    /// Once instantiated this file is proven to exist.
    let workingDirectory: URL
    /// The URL to the `Tests` folder inside the SPM project.
    /// Once instantiated this file is proven to exist.
    let testsDirectory: URL

    /// Holds all the test targets (parsed form the configuration) which the Runner will execute.
    var testTargets: [NegativeTestTarget] = []
    /// Collected compiler errors which we didn't expect
    var unexpectedErrors: Set<UnexpectedError> = []
    /// A string of paths of test case directories or files we already copied, such that we
    /// cann restore initial state even when we encounter some sort of error!
    var pathsOfCopiedTestCases: [String] = []

    private let errorDefinitionPattern: NSRegularExpression
    private let compilerErrorPattern: NSRegularExpression

    init() throws {
        self.workingDirectory = try XCTUnwrap(URL(string: #filePath))
            .deletingLastPathComponent() // removing "NegativeTestRunner.swift"
            .deletingLastPathComponent() // removing "NegativeCompileTestsRunner"
            .deletingLastPathComponent() // remoivng "Tests"
        self.testsDirectory = workingDirectory.appendingPathComponent("Tests")
        
        print("Project directory: \(workingDirectory.absoluteString)")
        
        self.errorDefinitionPattern = try NSRegularExpression(pattern: "^.*// error: (.*)$")
        self.compilerErrorPattern = try NSRegularExpression(pattern: "^([^:]*):([0-9]+):(([0-9]+):)? error: (.*)$")

        if !fileManager.directoryExists(at: testsDirectory) {
            fatalError("""
                       NegativeCompileTestsRunner must be run in the root directory of the SPM project! \
                       \(workingDirectory.absoluteString) does not contain the 'Tests' folder!
                       """)
        }
    }

    func run() throws {
        print("Running test targets...")
        
        for target in testTargets {
            do {
                try buildTarget(target: target)
            } catch {
                cleanup()
                throw error
            }
        }
    }

    func evaluateResults() {
        print("Evaluation results...")

        var failed = false

        for target in testTargets {
            for testCase in target.cases {
                for error in testCase.expectedErrors {
                    if !error.triggered {
                        XCTFail("Expected compiler error was not triggered: \(error.filePath):\(error.line): \(error.errorMessage)")
                        failed = true
                    }

                    for differingMessage in error.differingMessages {
                        XCTFail("""
                                Differing error message for compiler error: \(error.filePath):\(error.line):
                                    Found '\(differingMessage)'
                                    while expecting '\(error.errorMessage)'
                                """)
                        failed = true
                    }
                }
            }
        }

        for error in unexpectedErrors {
            XCTFail("Unexpected compiler error: \(error.rawLine)")
            failed = true
        }

        if !failed {
            print("Negative Compile Tests ran successfully!")
        }
    }

    func prepareConfiguration() throws {
        print("Parsing configuration...")
        
        for target in configurations {
            var testCases: [NegativeTestCase] = []

            let targetDirectory = testsDirectory.appendingPathComponent(target.name)
            let casesDirectory = targetDirectory.appendingPathComponent("Cases")

            if !fileManager.directoryExists(at: targetDirectory) {
                fatalError("Could not find specified test target directory '\(targetDirectory.relativePath)' or its not a directory!")
            } else if !fileManager.directoryExists(at: casesDirectory) {
                fatalError("Could not find the 'Cases' directory inside the test target or not a directory: \(casesDirectory.relativePath)")
            }

            let contents = try fileManager.contentsOfDirectory(
                at: casesDirectory,
                includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey],
                options: .skipsHiddenFiles
            )

            if contents.isEmpty {
                fatalError("The 'Cases' directory of the '\(target.name)' target does not contain any test cases!")
            }

            for contentUrl in contents {
                if target.isExcludedCase(contentUrl.lastPathComponent) {
                    continue
                }

                let destination = targetDirectory.appendingPathComponent(contentUrl.lastPathComponent)
                var expectedErrors: [ExpectedError] = []

                try parseTestCaseFile(fileURL: contentUrl, collecting: &expectedErrors)

                testCases.append(NegativeTestCase(fileUrl: contentUrl, destinationUrl: destination, expectedErrors: expectedErrors))
            }


            testTargets.append(NegativeTestTarget(directory: targetDirectory, casesDirectory: casesDirectory, cases: testCases))
        }
    }

    private func parseTestCaseFile(fileURL: URL, collecting expectedErrors: inout [ExpectedError]) throws {
        let resourceValues = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .isDirectoryKey])

        if resourceValues.isDirectory == true {
            print("Entering DIR \(fileURL.path)")
            let contents = try fileManager.contentsOfDirectory(
                at: fileURL,
                includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey],
                options: .skipsHiddenFiles
            )

            for content in contents {
                try parseTestCaseFile(fileURL: content, collecting: &expectedErrors)
            }

            return
        } else if resourceValues.isRegularFile != true {
            fatalError("Unexpected file: \(fileURL.path)")
        }

        print("Reading FILE \(fileURL.path)")

        guard let data = fileManager.contents(atPath: fileURL.path) else {
            fatalError("Error occurred when trying to read content of file \(fileURL.path)")
        }
        guard let fileContent = String(data: data, encoding: .utf8) else {
            fatalError("Failed to parse string of file contents of file \(fileURL.path)")
        }

        let lines = fileContent.split(separator: "\n", omittingEmptySubsequences: false).map {
            String($0)
        }

        var foundCount = 0
        var lineNumber = 1
        for line in lines {
            let matches = errorDefinitionPattern.matches(in: line, range: NSRange(line.startIndex..., in: line))

            guard let match = matches.first, matches.count == 1 else {
                lineNumber += 1
                continue
            }

            let expectedErrorMessage = line.retrieveMatch(match: match, at: 1).filter { character in
                character.isASCII // potentially trimming any control characters
            }

            expectedErrors.append(ExpectedError(
                filePath: fileURL.path.replacingOccurrences(of: "Cases/", with: ""),
                line: lineNumber + 1,
                errorMessage: expectedErrorMessage
            ))

            foundCount += 1

            lineNumber += 1
        }

        print("Found \(foundCount) error declaration\(foundCount != 1 ? "s": "") in \(fileURL.path)")
    }

    private func buildTarget(target: NegativeTestTarget) throws {
        print("[\(target.name)] Copying test case files...")
        for testCase in target.cases {
            try fileManager.copyItem(atPath: testCase.fileUrl.path, toPath: testCase.destinationUrl.path)

            pathsOfCopiedTestCases.append(testCase.destinationUrl.path)
        }

        runCommand(command: "ls -al \(target.directory)")

        #if DEBUG
        let stdOutput = runCommand(command: "swift build --build-tests", expectedStatus: 1)
        #else
        let stdOutput = runCommand(command: "swift build --build-tests -c release -Xswiftc -enable-testing", expectedStatus: 1)
        #endif

        print("[\(target.name)] Scanning results for target \(target.name)...")

        let lines = stdOutput.split(separator: "\n", omittingEmptySubsequences: false).map {
            String($0)
        }

        for line in lines {
            let matches = compilerErrorPattern.matches(in: line, range: NSRange(line.startIndex..., in: line))

            guard let match = matches.first, matches.count == 1 else {
                continue
            }

            let filePath = line.retrieveMatch(match: match, at: 1)
            let lineNumber = Int(line.retrieveMatch(match: match, at: 2)) ?? -1
            let column = Int(line.retrieveMatch(match: match, at: 4))
            let errorMessage = line.retrieveMatch(match: match, at: 5)

            let marked = markExpectedErrorTriggered(in: target, absolutePath: filePath, line: lineNumber, error: errorMessage)
            if !marked {
                self.unexpectedErrors.insert(
                    UnexpectedError(filePath: filePath, line: lineNumber, column: column, errorMessage: errorMessage, rawLine: line)
                )
            }
        }

        cleanup()
    }

    @discardableResult
    private func runCommand(command: String, expectedStatus: Int32 = 0) -> String { // swiftlint:disable:this function_body_length
        var parts: [String] = []

        print("-----------------------------")
        print("Running command '\(command)'...")

        let process = Process()
        process.launchPath = "/usr/bin/env"
        process.arguments = ["zsh", "-c", command]
        process.currentDirectoryPath = workingDirectory.path
        
        // https://stackoverflow.com/questions/67595371/swift-package-calling-usr-bin-swift-errors-with-failed-to-open-macho-file-to
        if ProcessInfo.processInfo.environment.keys.contains("OS_ACTIVITY_DT_MODE") {
            print("Clearing OS_ACTIVITY_DT_MODE environment variable")
            var environment = ProcessInfo.processInfo.environment
            environment["OS_ACTIVITY_DT_MODE"] = nil
            process.environment = environment
        }

        let stdOutPipe = Pipe()
        let stdErrPipe = Pipe()

        process.standardOutput = stdOutPipe
        process.standardError = stdErrPipe

        let stdOutReadingHandle = stdOutPipe.fileHandleForReading
        let stdErrReadingHandle = stdErrPipe.fileHandleForReading

        stdOutReadingHandle.waitForDataInBackgroundAndNotify()
        stdErrReadingHandle.waitForDataInBackgroundAndNotify()

        let stdOutObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.NSFileHandleDataAvailable,
            object: stdOutReadingHandle,
            queue: nil) { _ in
            let data = stdOutReadingHandle.availableData

            guard !data.isEmpty else { // EOF
                return
            }

            let part = String(data: data, encoding: .utf8) ?? ""
            print(part, terminator: "")

            parts.append(part)

            stdOutReadingHandle.waitForDataInBackgroundAndNotify()
        }

        let stdErrObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.NSFileHandleDataAvailable,
            object: stdOutReadingHandle,
            queue: nil) { _ in
            let data = stdErrReadingHandle.availableData

            guard !data.isEmpty else { // EOF
                return
            }

            FileHandle.standardError.write(data)

            stdErrReadingHandle.waitForDataInBackgroundAndNotify()
        }

        process.launch()
        process.waitUntilExit()

        NotificationCenter.default.removeObserver(stdOutObserver)
        NotificationCenter.default.removeObserver(stdErrObserver)
        
        // sometimes there is still data left which wasn't passed to the Observer
        let remainingStdOutData = stdOutReadingHandle.readDataToEndOfFile()
        let remainingStdErrData = stdErrReadingHandle.readDataToEndOfFile()
        
        if let remainigStdOut = String(data: remainingStdOutData, encoding: .utf8) {
            parts.append(remainigStdOut)
            print(remainigStdOut, terminator: "")
        }
        
        if !remainingStdErrData.isEmpty {
            FileHandle.standardError.write(remainingStdErrData)
        }

        print("---------- EXIT: \(process.terminationStatus) (expected: \(expectedStatus)) ----------")
        
        XCTAssertEqual(expectedStatus, process.terminationStatus, "Found unexpected exit code for above process run!")

        return parts.joined()
    }

    private func markExpectedErrorTriggered(in target: NegativeTestTarget, absolutePath path: String, line: Int, error message: String) -> Bool {
        var found = false

        for testCase in target.cases {
            if !path.starts(with: testCase.destinationUrl.path) {
                continue
            }

            for error in testCase.expectedErrors where error.filePath == path && error.line == line {
                found = true
                error.markTriggered(with: message)
            }
        }

        return found
    }

    private func cleanup() {
        for path in pathsOfCopiedTestCases {
            do {
                try fileManager.removeItem(atPath: path)
            } catch {
                print("error: Failed to remove test case: \(error)")
            }
        }

        pathsOfCopiedTestCases.removeAll()
    }
}
