//
//  Task.swift
//  
//
//  Created by Lukas Kollmer on 2020-12-31.
//

import Foundation
import Dispatch
import CApodiniDeployBuildSupport

#if os(Linux)
import Glibc
#else
import Darwin
#endif



/// A wrapper around `Foundation.Process` (née`NSTask`)
public class Task {
    private static let taskPool = ThreadSafeVariable<Set<Task>>([])
    private static var didRegisterAtexitHandler = false
    
    // value for argv[1] if we're supposed to turn into a child process invocation
    private static let processIsChildProcessInvocationWrapper =
        String(cString: ApodiniProcessIsChildInvocationWrapperCLIArgument)
    
    
    public enum TaskError: Swift.Error {
        case other(String)
    }
    
    public struct TerminationInfo {
        public let exitCode: Int32
        public let reason: Process.TerminationReason
    }
    
    public typealias TerminationHandler = (TerminationInfo) -> Void
    
    private let process: Process
    
    public let executableUrl: URL
    private var didRun = false
    private var terminationHandler: TerminationHandler?
    
    private let stdoutPipe = Pipe()
    private let stderrPipe = Pipe()
    private let stdinPipe = Pipe()
    
    /// Whether the launched task should be put into the same process group as the current process.
    /// Any still-running tasks put in the same group as the current process will be terminated when when the current process exits.
    private let launchInCurrentProcessGroup: Bool
    
    public var arguments: [String] {
        willSet { assertCanMutate() }
    }
    
    public var environment: [String: String] {
        willSet { assertCanMutate() }
    }
    /// Whether the process should inherit its parent's (ie, the current process') environment variables
    public var inheritsParentEnvironment: Bool {
        willSet { assertCanMutate() }
    }
    
    
    public var pid: Int32 {
        process.processIdentifier
    }
    public var isRunning: Bool { process.isRunning }
    
    
    private func assertCanMutate() {
        precondition(!isRunning, "Cannot mutate running task")
    }
    
    
    public init(
        executableUrl: URL,
        arguments: [String] = [],
        workingDirectory: URL? = nil,
        captureOutput: Bool = false, // setting this to false will cause the output to show up in stdout
        launchInCurrentProcessGroup: Bool,
        environment: [String: String] = [:],
        inheritsParentEnvironment: Bool = true // ?inheritsEnvironmentFromParent?
    ) {
        self.executableUrl = executableUrl
        self.arguments = arguments
        self.launchInCurrentProcessGroup = launchInCurrentProcessGroup
        self.environment = environment
        self.inheritsParentEnvironment = inheritsParentEnvironment
        process = Process()
        process.currentDirectoryURL = workingDirectory?.absoluteURL // apparently Process doesn't properly resolve relative urls?
        process.terminationHandler = { [weak self] process in
            self?.processTerminationHandlerImpl(process: process)
        }
        process.environment = environment
        if captureOutput {
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe
            process.standardInput = stdinPipe
        }
        Self.registerAtexitHandlerIfNecessary()
    }
    
    
    private func launchImpl() throws {
        precondition(!didRun)
        print("-[\(Self.self) \(#function)] \(taskStringRepresentation)")
        if launchInCurrentProcessGroup {
            process.executableURL = LKGetCurrentExecutableUrl()
            process.arguments = [Self.processIsChildProcessInvocationWrapper, self.executableUrl.path] + self.arguments
            Self.taskPool.write { $0.insert(self) }
        } else {
            process.executableURL = self.executableUrl
            process.arguments = self.arguments
        }
        if inheritsParentEnvironment {
            process.environment = ProcessInfo.processInfo.environment
            for (key, value) in self.environment {
                process.environment![key] = value
            }
        } else {
            process.environment = self.environment
        }
        didRun = true
        try process.run()
    }
    
    
    public func launchSync() throws -> TerminationInfo {
        try launchImpl()
        process.waitUntilExit()
        return TerminationInfo(exitCode: process.terminationStatus, reason: process.terminationReason)
    }
    
    
    public func launchAsync(_ terminationHandler: TerminationHandler? = nil) throws {
        self.terminationHandler = terminationHandler
        try launchImpl()
    }
    
    
    public func launchSyncAndAssertSuccess() throws {
        let terminationInfo = try launchSync()
        guard terminationInfo.exitCode == EXIT_SUCCESS else {
            fatalError("Task '\(taskStringRepresentation)' terminated with non-zero exit code \(terminationInfo.exitCode)")
        }
    }
    
    
    public func terminate() {
        process.terminate()
    }
    
    
    private func processTerminationHandlerImpl(process: Process) {
        precondition(process == self.process)
        self.terminationHandler?(TerminationInfo(exitCode: process.terminationStatus, reason: process.terminationReason))
        self.terminationHandler = nil
        Self.taskPool.write { $0.remove(self) }
    }
    
    
    public func readStdout(usingStringEncoding encoding: String.Encoding = .utf8) throws -> String {
        try stdoutPipe.readUntilEndAsString(encoding: encoding)
    }
    
    public func readStderr(usingStringEncoding encoding: String.Encoding = .utf8) throws -> String {
        try stderrPipe.readUntilEndAsString(encoding: encoding)
    }
    
    
    public var taskStringRepresentation: String {
        var str = "\(executableUrl.path)"
        if !arguments.isEmpty {
            str += " " + arguments.joined(separator: " ")
        }
        return str
    }
}



extension Task: Hashable, Equatable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
    
    public static func == (lhs: Task, rhs: Task) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}






extension Task {
    static func registerAtexitHandlerIfNecessary() {
        guard !didRegisterAtexitHandler else {
            return
        }
        didRegisterAtexitHandler = true
        atexit {
            Task.taskPool.read { tasks in
                for task in tasks where task.isRunning {
                    task.terminate()
                }
            }
        }
    }
}



extension Task {
    public static func findExecutable(named binaryName: String) -> URL? {
        guard let searchPaths = ProcessInfo.processInfo.environment["PATH"]?.components(separatedBy: ":") else {
            return nil
        }
        let FM = FileManager.default
        for searchPath in searchPaths {
            let executableUrl = URL(fileURLWithPath: searchPath, isDirectory: true)
                .appendingPathComponent(binaryName, isDirectory: false)
            if FM.fileExists(atPath: executableUrl.path) {
                return executableUrl
            }
        }
        return nil
    }
}



extension Pipe {
    func readUntilEndAsString(encoding: String.Encoding) throws -> String {
        guard
            let data = try self.fileHandleForReading.readToEnd(),
            let string = String(data: data, encoding: encoding)
        else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to read string from pipe"])
        }
        return string
    }
}
