//
//  SignalHandling.swift
//  
//
//  Created by Lukas Kollmer on 2021-01-18.
//


#if os(Linux)
import Glibc
#else
import Darwin
#endif


public struct Signal: RawRepresentable, Hashable, Equatable {
    public let rawValue: Int32
    
    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }
    
    public static let HUP  = Signal(rawValue: SIGHUP)
    public static let INT  = Signal(rawValue: SIGINT)
    public static let QUIT = Signal(rawValue: SIGQUIT)
    public static let ILL  = Signal(rawValue: SIGILL)
    public static let TRAP = Signal(rawValue: SIGTRAP)
    public static let ABRT = Signal(rawValue: SIGABRT)
    public static let KILL = Signal(rawValue: SIGKILL)
    public static let TERM = Signal(rawValue: SIGTERM)
}



public enum SignalHandling {
    public typealias SignalHandler = (Signal) -> Void
    
    
    public class SignalHandlerToken {
        fileprivate var handler: SignalHandler?
        
        fileprivate init(handler: @escaping SignalHandler) {
            self.handler = handler
        }
        
        public func invalidate() {
            // Invalidating a signal handler will keep the token in the array,
            // but nil out the handler (which will relase the closure)
            handler = nil
        }
    }

    
    private static var handlersBySignal: [Signal: [SignalHandlerToken]] = [:]
    
    @discardableResult
    public static func add(for signal: Signal, handler: @escaping SignalHandler) -> SignalHandlerToken {
        _initSystemSignalHandlerIfNecessary(signal)
        let token = SignalHandlerToken(handler: handler)
        handlersBySignal[signal]!.append(token)
        return token
    }
    
    
    private static func _initSystemSignalHandlerIfNecessary(_ _signal: Signal) { // underscored so that we can access the signal function w/out having to qualify the name
        guard handlersBySignal[_signal] == nil else {
            // make sure we register only one handler per signal
            return
        }
        handlersBySignal[_signal] = []
        signal(_signal.rawValue) { signalValue in
            let signal = Signal(rawValue: signalValue)
            Self.handlersBySignal[signal]?.forEach { $0.handler?(signal) }
        }
    }
}




/*
/* sigcontext; codes for SIGILL, SIGFPE */

public var SIGHUP: Int32 { get } /* hangup */
public var SIGINT: Int32 { get } /* interrupt */
public var SIGQUIT: Int32 { get } /* quit */
public var SIGILL: Int32 { get } /* illegal instruction (not reset when caught) */
public var SIGTRAP: Int32 { get } /* trace trap (not reset when caught) */
public var SIGABRT: Int32 { get } /* abort() */

/* pollable event ([XSR] generated, not supported) */
/* (!_POSIX_C_SOURCE || _DARWIN_C_SOURCE) */
public var SIGIOT: Int32 { get } /* compatibility */
public var SIGEMT: Int32 { get } /* EMT instruction */
/* (!_POSIX_C_SOURCE || _DARWIN_C_SOURCE) */
public var SIGFPE: Int32 { get } /* floating point exception */
public var SIGKILL: Int32 { get } /* kill (cannot be caught or ignored) */
public var SIGBUS: Int32 { get } /* bus error */
public var SIGSEGV: Int32 { get } /* segmentation violation */
public var SIGSYS: Int32 { get } /* bad argument to system call */
public var SIGPIPE: Int32 { get } /* write on a pipe with no one to read it */
public var SIGALRM: Int32 { get } /* alarm clock */
public var SIGTERM: Int32 { get } /* software termination signal from kill */
public var SIGURG: Int32 { get } /* urgent condition on IO channel */
public var SIGSTOP: Int32 { get } /* sendable stop signal not from tty */
public var SIGTSTP: Int32 { get } /* stop signal from tty */
public var SIGCONT: Int32 { get } /* continue a stopped process */
public var SIGCHLD: Int32 { get } /* to parent on child stop or exit */
public var SIGTTIN: Int32 { get } /* to readers pgrp upon background tty read */
public var SIGTTOU: Int32 { get } /* like TTIN for output if (tp->t_local&LTOSTOP) */

public var SIGIO: Int32 { get } /* input/output possible signal */

public var SIGXCPU: Int32 { get } /* exceeded CPU time limit */
public var SIGXFSZ: Int32 { get } /* exceeded file size limit */
public var SIGVTALRM: Int32 { get } /* virtual time alarm */
public var SIGPROF: Int32 { get } /* profiling time alarm */

public var SIGWINCH: Int32 { get } /* window size changes */
public var SIGINFO: Int32 { get } /* information request */

public var SIGUSR1: Int32 { get } /* user defined signal 1 */
public var SIGUSR2: Int32 { get } /* user defined signal 2 */
*/
