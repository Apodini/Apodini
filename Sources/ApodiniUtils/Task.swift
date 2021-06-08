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
    
    
    public enum StdioType: CaseIterable {
        case stdout, stderr, stdin
    }
    
    /// Function type used to observe a task's output.
    /// 1st parameter indicates the origin of this specific event (stdout or stderr, unless the two were merged).
    /// 2nd parameter are the data written by the task. 3rd parameter is the task itself.
    public typealias StdioObserverSignature = (StdioType, Data, Task) -> Void
    private typealias StdioObserverRegistrationToken = Box<StdioObserverSignature>
    
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
    
    private var stdioFileHandlesObserverTokens: (AnyObject, AnyObject)?
    private var didRegisterStdioFileHandleObservers: Bool {
        stdioFileHandlesObserverTokens != nil
    }
    private var registeredStdioHandlers: [Weak<StdioObserverRegistrationToken>] = []
    
    /// Whether the launched task should be put into the same process group as the current process.
    /// Any still-running tasks put in the same group as the current process will be terminated when when the current process exits.
    private let launchInCurrentProcessGroup: Bool
    
    /// The argv with which the task will be launched.
    /// - Note: this property can only be mutated while as the task is not running
    public var arguments: [String] {
        willSet { try! assertCanMutate() } // swiftlint:disable:this force_try
    }
    
    /// The task's environment variables
    /// - Note: this property can only be mutated while as the task is not running
    public var environment: [String: String?] {
        willSet { try! assertCanMutate() } // swiftlint:disable:this force_try
    }
    
    /// Whether the process should inherit its parent's (ie, the current process') environment variables
    /// - Note: this property can only be mutated while as the task is not running
    public var inheritsParentEnvironment: Bool {
        willSet { try! assertCanMutate() } // swiftlint:disable:this force_try
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
    ///         If this value is `false`, the child will be launched with only the environment variables specified in its own environment (see the `environment` parameter, and the property with the same name).
    ///         If this value is `true`, the child's environment will be constructed by merging the current process' environment with the values specified for the child,
    ///         with the child's values taking precedence if a key exists in both environments and a value if nil unsetting any inherited environment variables.
    public init(
        executableUrl: URL,
        arguments: [String] = [],
        workingDirectory: URL? = nil,
        captureOutput: Bool = false,
        redirectStderrToStdout: Bool = false,
        launchInCurrentProcessGroup: Bool,
        environment: [String: String?] = [:],
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
    
    
    deinit {
        if let fileHandleObservers = stdioFileHandlesObserverTokens {
            NotificationCenter.default.removeObserver(fileHandleObservers.0)
            NotificationCenter.default.removeObserver(fileHandleObservers.1)
            stdioFileHandlesObserverTokens = nil
        }
        print("Task.deinit")
    }
    
    
    private func launchImpl() throws {
        precondition(!isRunning)
        print("-[\(Self.self) \(#function)] \(self)")
        if launchInCurrentProcessGroup {
            process.executableURL = ProcessInfo.processInfo.executableUrl
            process.arguments = [Self.processIsChildProcessInvocationWrapper, self.executableUrl.path] + self.arguments
            Self.taskPool.write { $0.insert(self) }
        } else {
            process.executableURL = self.executableUrl
            process.arguments = self.arguments
        }
        if inheritsParentEnvironment {
            var environment = ProcessInfo.processInfo.environment

            for (key, value) in self.environment {
                if let environmentValue = value {
                    environment[key] = environmentValue
                } else {
                    environment[key] = nil
                }
            }

            process.environment = environment
        } else {
            process.environment = self.environment
                .filter { _, value in
                    value != nil
                }
                .mapValues { value -> String in
                    value! // swiftlint:disable:this force_unwrapping
                }
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
    
    
    /// Launch the task synchronously and throw an error if the task did not exit successfully
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
    /// Merge the task's stdout and stderr streams.
    /// This will redirect stderr to stdout.
    public func mergeStdoutAndStderr() throws {
        try assertCanMutate()
        process.standardError = stdoutPipe
    }
    
    /// Whether the task is capturing the child's standard output stream
    public var isCapturingStdout: Bool {
        (process.standardOutput as? Pipe) == stdoutPipe
    }
    
    /// Whether the task is capturing the child's standard error stream
    public var isCapturingStderr: Bool {
        if let stderr = process.standardError as? Pipe {
            return stderr == stderrPipe || stderr == stdoutPipe
        } else {
            return false
        }
    }
    
    /// Whether the task is capturing the child's standard input stream
    public var isCapturingStdin: Bool {
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
            try! assertCanMutate() // swiftlint:disable:this force_try
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
    
    
    /// Register an observer function which will get called when the task emits output.
    /// This will observe data written to both the task's standard output stream as well as its standard error stream.
    public func observeOutput(_ handler: @escaping StdioObserverSignature) -> AnyObject {
        registerStdioFileHandleObserversIfNecessary()
        let registration = Box<StdioObserverSignature>(handler)
        registeredStdioHandlers.append(Weak(registration))
        return registration
    }
    
    
    private func registerStdioFileHandleObserversIfNecessary() {
        guard !didRegisterStdioFileHandleObservers else {
            return
        }
        
        func imp(fileHandle fileHandleToObserve: FileHandle, stdioType: StdioType) -> AnyObject {
            fileHandleToObserve.waitForDataInBackgroundAndNotify()
            return NotificationCenter.default.addObserver(
                forName: .NSFileHandleDataAvailable,
                object: fileHandleToObserve,
                queue: nil
            ) { [weak self] notification in
                guard let self = self, let fileHandle = notification.object as? FileHandle, fileHandle == fileHandleToObserve else {
                    return
                }

                let data = fileHandle.availableData
                if !data.isEmpty {
                    self.registeredStdioHandlers
                        .compactMap(\.value?.value)
                        .forEach { $0(stdioType, data, self) }
                }
                
                fileHandle.waitForDataInBackgroundAndNotify()
            }
        }
        
        stdioFileHandlesObserverTokens = (
            imp(fileHandle: stdoutPipe.fileHandleForReading, stdioType: .stdout),
            imp(fileHandle: stderrPipe.fileHandleForReading, stdioType: .stderr)
        )
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
    /// Attempts to find the location of the executable with the specified name, by looking through the current environment's search paths.
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
    /// However, since we want to retain the 10.15 deployment target, and SPM does not support specifying minor versions,
    /// we need this workaround.
    func tryReadDataToEnd() throws -> Data? {
        if #available(macOS 10.15.4, *) {
            return try readToEnd()
        } else {
            return readDataToEndOfFile()
        }
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
