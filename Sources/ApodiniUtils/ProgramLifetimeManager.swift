import NIO
import Dispatch


/// Helper type which will provide a future you can wait on to keep your programm running,
/// until it either crashes or receives a `SIGTERM` or `SIGINT` signal (i.e. was terminated by the user).
public class ProgramLifetimeManager {
    private var promise: EventLoopPromise<Void>?
    private var signalSources: [DispatchSourceSignal] = []
    
    /// Whether the program currently is running
    public var isRunning: Bool { promise != nil }
    
    /// The Initialiser
    public init() {}
    
    /// Start a program lifecycle
    /// - returns: a future you can `wait()` on that will succeed once the program received either the `SIGTERM` or `SIGINT` signal
    public func start(on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        precondition(!isRunning, "Cannot start lifecycle that is already running")
        let promise = eventLoop.makePromise(of: Void.self)
        promise.futureResult.whenComplete { [unowned self] _ in
            self.promise = nil
            self.signalSources.removeAll()
        }
        // setup signal sources for shutdown
        let signalQueue = DispatchQueue(label: "org.apodini.\(Self.self).shutdownSignalHandler")
        func makeSignalSource(_ code: Int32) {
            let source = DispatchSource.makeSignalSource(signal: code, queue: signalQueue)
            source.setEventHandler {
                print() // clear ^C
                promise.succeed(())
            }
            source.resume()
            self.signalSources.append(source)
            signal(code, SIG_IGN)
        }
        makeSignalSource(SIGTERM)
        makeSignalSource(SIGINT)
        return promise.futureResult
    }
    
    /// Stop the program, by fulfilling the promise.
    public func stop() {
        promise?.succeed(())
    }
}
