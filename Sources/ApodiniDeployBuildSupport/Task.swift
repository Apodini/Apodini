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



// Note: I have no idea if this is a good implementation, works property, or even makes sense.
// There was an issue where accessing the `Task.taskPool` static variable from w/in the atexit
// handler would fail but only sometimes (for some reason the atexit handler was being invoked
// off the main thread). Adding this fixed the issue.
class ThreadSafeVariable<T> {
    private var value: T
    private let queue: DispatchQueue
    
    init(_ value: T) {
        self.value = value
        self.queue = DispatchQueue(label: "Apodini.ThreadSafeVariable", attributes: .concurrent)
    }
    
    
    func read(_ block: (T) throws -> Void) rethrows {
        try queue.sync {
            try block(value)
        }
    }
    
    
    func write(_ block: (inout T) throws -> Void) rethrows {
        try queue.sync(flags: .barrier) {
            try block(&value)
        }
    }
}




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
        willSet {
            precondition(!didRun, "Cannot change arguments of already launched task")
        }
    }
    
    public var pid: Int32 { process.processIdentifier }
    
    public init(
        executableUrl: URL,
        arguments: [String] = [],
        workingDirectory: URL? = nil,
        captureOutput: Bool = false, // setting this to false will cause the output to show up in stdout
        launchInCurrentProcessGroup: Bool
    ) {
        self.executableUrl = executableUrl
        self.arguments = arguments
        self.launchInCurrentProcessGroup = launchInCurrentProcessGroup
        process = Process()
        process.currentDirectoryURL = workingDirectory
        process.terminationHandler = { [weak self] process in
            self?.processTerminationHandlerImpl(process: process)
        }
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
            //process.executableURL = LKGetCurrentExecutableUrl()
            //process.arguments = [Self.processIsChildProcessInvocationWrapper, self.executableUrl.path] + self.arguments
            process.executableURL = self.executableUrl
            process.arguments = self.arguments
            Self.taskPool.write { set in
                set.insert(self)
            }
        } else {
            process.executableURL = self.executableUrl
            process.arguments = self.arguments
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
        Self.taskPool.write { set in
            set.remove(self)
        }
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
            Task.taskPool.read { set in
                for task in set {
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
