//
//  Task.swift
//  
//
//  Created by Lukas Kollmer on 2020-12-31.
//

import Foundation
import Dispatch
import CApodiniUtils
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
    
    
    public struct TaskError: Swift.Error {
        public let message: String
    }
    
    /// Info about why and how a task was terminated
    public struct TerminationInfo {
        /// Exit code type
        public typealias ExitCode = Int32
        /// Termination reason type
        public typealias TerminationReason = Process.TerminationReason
        
        /// The task's exit code
        public let exitCode: ExitCode
        /// The task's termination reason
        public let reason: TerminationReason
    }
    
    /// Termination handler type alias
    public typealias TerminationHandler = (TerminationInfo) -> Void
    
    private let process: Process
    
    /// The url of the task's executable
    public let executableUrl: URL
    /// Whether the task currently is running
    private(set) var isRunning = false
    private var terminationHandler: TerminationHandler?
    
    private let stdoutPipe = Pipe()
    private let stderrPipe = Pipe()
    private let stdinPipe = Pipe()
    
    /// Whether the launched task should be put into the same process group as the current process.
    /// Any still-running tasks put in the same group as the current process will be terminated when when the current process exits.
    private let launchInCurrentProcessGroup: Bool
    
    /// The argv with which the task will be launched.
    /// - Note: this property can only be mutated while as the task is not running
    public var arguments: [String] {
        willSet { try! assertCanMutate() }
    }
    
    /// The task's environment variables
    /// - Note: this property can only be mutated while as the task is not running
    public var environment: [String: String] {
        willSet { try! assertCanMutate() }
    }
    
    /// Whether the process should inherit its parent's (ie, the current process') environment variables
    /// - Note: this property can only be mutated while as the task is not running
    public var inheritsParentEnvironment: Bool {
        willSet { try! assertCanMutate() }
    }
    
    
    /// The task's process identifier.
    /// - Note: If the task is not running, the value of this property is undefined
    public var pid: Int32 {
        process.processIdentifier
    }
    
    private func assertCanMutate() throws {
        guard !isRunning else {
            throw TaskError(message: "Cannot mutate running task")
        }
    }
    
    
    /// Creates a new `Task` object and configures it using the specified options
    /// - parameter captureOutput: A boolean value indicating whether the task should capture its child process' output.
    ///         If this value is `true`, the child's output (both stdout and stderr) will be available via the respective APIs.
    ///         Capturing output also means that the child's stdout and stderr will not show up in the parent's stdout and stderr.
    ///         If this value is `false`, the APIs will not work, and the child's output will be printed to the current process' stdout and stderr.
    /// - parameter launchInCurrentProcessGroup: Whether the child should be launched in the same process group as the parent.
    ///         Launching the child into the parent's process group means that the child will receive all signals sent to the parent (eg `SIGINT`, etc),
    ///         which is probably the desired behaviour if the child's lifetime is to be tied to the parent's lifetime.
    /// - parameter inheritsParentEnvironment: A boolean value indicating whether the child should, when launched, inherit the parent's environment variables.
    ///         If this value is `false`, the child will be launched with only the environment variables specified in its own environment (see the `enviromment` parameter, and the property with the same name).
    ///         If this value is `true`, the chlid's enviromnent will be constructed by merging the current process' enviromment with the values specified for the child,
    ///         with the child's values taking precedence if a key exists in both environments
    public init(
        executableUrl: URL,
        arguments: [String] = [],
        workingDirectory: URL? = nil,
        captureOutput: Bool = false,
        redirectStderrToStdout: Bool = false,
        launchInCurrentProcessGroup: Bool,
        environment: [String: String] = [:],
        inheritsParentEnvironment: Bool = true
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
        if redirectStderrToStdout {
            process.standardError = stdoutPipe
        }
        Self.registerAtexitHandlerIfNecessary()
    }
    
    
    private func launchImpl() throws {
        precondition(!isRunning)
        print("-[\(Self.self) \(#function)] \(self)")
//        for pipe in [stdoutPipe, stderrPipe, stdinPipe] {
//            pipe.fileHandleForReading.seek(toFileOffset: 0)
//            pipe.fileHandleForWriting.seek(toFileOffset: 0)
//        }
        if launchInCurrentProcessGroup {
            process.executableURL = ProcessInfo.processInfo.executableUrl
            process.arguments = [Self.processIsChildProcessInvocationWrapper, self.executableUrl.path] + self.arguments
            Self.taskPool.write { $0.insert(self) }
        } else {
            process.executableURL = self.executableUrl
            process.arguments = self.arguments
        }
        if inheritsParentEnvironment {
            process.environment = ProcessInfo.processInfo.environment
            for (key, value) in self.environment {
                process.environment![key] = value // swiftlint:disable:this force_unwrapping
            }
        } else {
            process.environment = self.environment
        }
        try process.run()
        isRunning = true
    }
    
    
    /// Launch the task synchronously
    public func launchSync() throws -> TerminationInfo {
        try launchImpl()
        process.waitUntilExit()
        return TerminationInfo(exitCode: process.terminationStatus, reason: process.terminationReason)
    }
    
    
    /// Launch the task asynchronously
    public func launchAsync(_ terminationHandler: TerminationHandler? = nil) throws {
        self.terminationHandler = terminationHandler
        try launchImpl()
    }
    
    
    /// Launch the task synchronously and throw an error if the task did not exit successfullly
    public func launchSyncAndAssertSuccess() throws {
        let terminationInfo = try launchSync()
        guard terminationInfo.exitCode == EXIT_SUCCESS else {
            fatalError("Task '\(self)' terminated with non-zero exit code \(terminationInfo.exitCode)")
        }
    }
    
    /// Terminate the task
    public func terminate() {
        sendSignal(SIGTERM)
    }
    
    /// Send a signal to the task
    public func sendSignal(_ signal: Int32) {
        kill(pid, signal)
    }
    
    
    private func processTerminationHandlerImpl(process: Process) {
        precondition(process == self.process)
        self.terminationHandler?(TerminationInfo(exitCode: process.terminationStatus, reason: process.terminationReason))
        self.terminationHandler = nil
        Self.taskPool.write { $0.remove(self) }
    }
}





// MARK: Task + Stdio Handling

extension Task {
    public func mergeStdoutAndStderr() throws {
        try assertCanMutate()
        process.standardError = stdoutPipe
    }
    
    
    var isCapturingStdout: Bool {
        (process.standardOutput as? Pipe) == stdoutPipe
    }
    
    var isCapturingStderr: Bool {
        if let stderr = process.standardError as? Pipe {
            return stderr == stderrPipe || stderr == stdoutPipe
        } else {
            return false
        }
    }
    
    var isCapturingStdin: Bool {
        (process.standardInput as? Pipe) == stdinPipe
    }
    
    
    /// Whether the task is capturing the child's stdout, stdin, and stderr.
    public var isCapturingStdio: Bool {
        isCapturingStdout && isCapturingStderr && isCapturingStdin
    }
    
    
    /// Whether the task's standard error is redirected to its standard output.
    public var isStderrRedirectedToStdout: Bool {
        get {
            if let errPipe = process.standardError as? Pipe {
                return errPipe == stdoutPipe
            } else {
                return false
            }
        }
        set {
            try! assertCanMutate()
            process.standardError = newValue ? stdoutPipe : stderrPipe
        }
    }
    
    
    
    /// Read the task's available stdout.
    /// - Note: This only works if the task was created with the `captureOutput` option set to `true`
    public func readStdoutToEnd(usingStringEncoding encoding: String.Encoding = .utf8) throws -> String {
        try stdoutPipe.readUntilEndAsString(encoding: encoding)
    }
    
    /// Read the task's available stderr.
    /// - Note: This only works if the task was created with the `captureOutput` option set to `true`
    public func readStderrToEnd(usingStringEncoding encoding: String.Encoding = .utf8) throws -> String {
        try stderrPipe.readUntilEndAsString(encoding: encoding)
    }
    
    
    /// - parameter handler: return value indicates whether the handler should continue receiving data.
    ///                      return `false` to cancel the observer.
    public func readStdout(_ handler: @escaping (Data, inout Bool) -> Void) {
        stdoutPipe.fileHandleForReading.readabilityHandler = { [unowned stdoutPipe] fileHandle in
            precondition(fileHandle == stdoutPipe.fileHandleForReading)
            precondition(fileHandle === stdoutPipe.fileHandleForReading)
            var shouldContinue = true
            if let data = try? fileHandle.tryReadDataToEnd() {
                handler(data, &shouldContinue)
            }
            if !shouldContinue {
                fileHandle.readabilityHandler = nil
            }
        }
    }
    
    
    /// Observe the task's output, i.e. data written to its standard out and standard error streams.
    /// - Note: If stderr was previously redirected to stdout, this function will, in its callback, report the stdio type for data read from stderr as stdout.
    public func observeOutput(_ handler: @escaping (StdioType, Data, Task, inout Bool) -> Void) -> AnyObject {
        func imp(_ stdioType: StdioType, _ fileHandleToObserve: FileHandle) -> AnyObject {
            fileHandleToObserve.waitForDataInBackgroundAndNotify()
            return NotificationCenter.default.addObserver(
                forName: .NSFileHandleDataAvailable,
                object: fileHandleToObserve,
                queue: nil
            ) { [weak self] (notification: Notification) in
                guard let self = self, let fileHandle = notification.object as? FileHandle, fileHandle == fileHandleToObserve else {
                    // Intentionally returning w/out calling -waitForDataInBackgroundAndNotify here,
                    // meaning that the observer block won't get called again.
                    return
                }
                
                let data = fileHandle.availableData
                var shouldContinue = true
                if !data.isEmpty {
                    handler(stdioType, data, self, &shouldContinue)
                }
                
                if shouldContinue {
                    fileHandle.waitForDataInBackgroundAndNotify()
                }
            }
        }
        return StdioObserverToken(notificationCenterObservers: [
            imp(.stdout, stdoutPipe.fileHandleForReading),
            imp(.stderr, stderrPipe.fileHandleForReading)
        ])
    }
    
    
    private class StdioObserverToken {
        let notificationCenterObservers: [AnyObject]
        
        init(notificationCenterObservers: [AnyObject]) {
            self.notificationCenterObservers = notificationCenterObservers
        }
        
        deinit {
            for observer in notificationCenterObservers {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
    
    public enum StdioType: CaseIterable {
        case stdout, stderr, stdin
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


extension Task: CustomStringConvertible {
    public var description: String {
        var properties: [(String, Any)] = [
            ("executableUrl", executableUrl.path),
            ("arguments", arguments),
            ("launchInCurrentProcessGroup", launchInCurrentProcessGroup),
            ("inheritsParentEnvironment", inheritsParentEnvironment),
            ("environment", environment),
            ("isRunning", isRunning)
        ]
        if isRunning {
            properties .append(("pid", pid))
        }
        return "<\(Self.self) \(properties.map { "\($0.0): \($0.1)" }.joined(separator: ", "))>"
    }
}


extension Task {
    /// Kill all child processes which were launched in the current process group and are currently running, by sending them the `SIGTERM` signal.
    public static func killAllInChildrenInProcessGroup() {
        print(#function)
        sendSignalToAllChildrenInProcessGroup(signal: SIGTERM)
    }
    
    /// Send a signal to all child processes which were launched into the current process' process group and are currently running.
    public static func sendSignalToAllChildrenInProcessGroup(signal: Int32) {
        Self.taskPool.read { tasks in
            for task in tasks where task.isRunning {
                task.sendSignal(signal)
            }
        }
    }
    
    private static func registerAtexitHandlerIfNecessary() {
        guard !didRegisterAtexitHandler else {
            return
        }
        didRegisterAtexitHandler = true
        atexit {
            Task.killAllInChildrenInProcessGroup()
        }
    }
}


extension Task {
    /// Attempts to find the location of the execitable with the specified name, by looking through the current environment's search paths.
    public static func findExecutable(named binaryName: String) -> URL? {
        guard let searchPaths = ProcessInfo.processInfo.environment["PATH"]?.components(separatedBy: ":") else {
            return nil
        }
        for searchPath in searchPaths {
            let executableUrl = URL(fileURLWithPath: searchPath, isDirectory: true)
                .appendingPathComponent(binaryName, isDirectory: false)
            if FileManager.default.fileExists(atPath: executableUrl.path) {
                return executableUrl
            }
        }
        return nil
    }
}


extension Pipe {
    func readUntilEndAsString(encoding: String.Encoding) throws -> String {
        guard
            let data = try fileHandleForReading.tryReadDataToEnd(),
            let string = String(data: data, encoding: encoding)
        else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to read string from pipe"])
        }
        return string
    }
}


extension FileHandle {
    /// A platform-specific wrapper around `-[FileHandle readToEnd]` (if running on an OS >= 10.15.4),
    /// or `-[FileHandle readDataToEndOfFile]` (if running on earlier OS versions).
    /// The two functions implement the same functionality, the difference being that the latter one
    /// might throw NSExceptions (which we can't really catch from Swift) and is marked for eventual deprecation.
    /// However, since we eant to retain the 10.15 deployment target, and SPM does not support specifying minor versions,
    /// we need this workaround.
    func tryReadDataToEnd() throws -> Data? {
        if #available(macOS 10.15.4, *) {
            return try readToEnd()
        } else {
            return readDataToEndOfFile()
        }
    }
    
    /// Attempts to determine whethet the file handle has data which can be read.
    public var isReadable: Bool {
        let fd = fileDescriptor
        var fdset = fd_set()
        var tmout = timeval()
        print(fdset)
        print(fdset.fds_bits)
        print(tmout)
        print(tmout.tv_sec, tmout.tv_usec)
        __darwin_fd_set(fd, &fdset)
        print("__darwin_set")
        print(fdset)
        print(fdset.fds_bits)
        print(tmout)
        print(tmout.tv_sec, tmout.tv_usec)
        let select_retval = select(fd + 1, &fdset, nil, nil, &tmout)
        print("select_retval: \(select_retval)")
        print(fdset)
        print(fdset.fds_bits)
        print(tmout)
        print(tmout.tv_sec, tmout.tv_usec)
        return select_retval > 0
    }
}


extension Process.TerminationReason: CustomStringConvertible {
    public var description: String {
        switch self {
        case .exit:
            return "\(Self.self).exit"
        case .uncaughtSignal:
            return "\(Self.self).uncaughtSignal"
        @unknown default:
            return "\(Self.self).\(self.rawValue)"
        }
    }
}


// Note: I have no idea if this is a good implementation, works property, or even makes sense.
// There was an issue where accessing the `Task.taskPool` static variable from w/in the atexit
// handler would fail but only sometimes (for some reason the atexit handler was being invoked
// off the main thread). Adding this fixed the issue.
public class ThreadSafeVariable<T> {
    private var value: T
    private let queue: DispatchQueue
    
    public init(_ value: T) {
        self.value = value
        self.queue = DispatchQueue(label: "Apodini.ThreadSafeVariable", attributes: .concurrent)
    }
    
    
    public func read(_ block: (T) throws -> Void) rethrows {
        try queue.sync {
            try block(value)
        }
    }
    
    
    public func write(_ block: (inout T) throws -> Void) rethrows {
        try queue.sync(flags: .barrier) {
            try block(&value)
        }
    }
}

