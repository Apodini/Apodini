//
//  System.swift
//  
//
//  Created by Lukas Kollmer on 16.02.21.
//

import Foundation
#if canImport(MachO)
import MachO
#endif



public func throwIfPosixError(_ posixErrno: Int32) throws {
    guard posixErrno != 0 else { return }
    throw NSError(domain: NSPOSIXErrorDomain, code: Int(posixErrno), userInfo: [
        NSLocalizedDescriptionKey: getErrnoString() ?? ""
    ])
}


public func getErrnoString() -> String? {
    if let cString = strerror(errno) {
        return String(cString: cString)
    } else {
        return nil
    }
}


extension ProcessInfo {
    /// The group id of the current process
    public var lk_groupId: pid_t { getpgrp() }
    
    /// The process id of the current process's parent
    public var lk_parentProcessId: pid_t { getppid() }
    
    /// The group id of the current process's parent
    public var lk_parentGroupId: pid_t { getpgid(lk_parentProcessId) }
}


//precondition(URL(fileURLWithPath: ProcessInfo.processInfo.arguments[0]) == Bundle(for: Self.self).executableURL!)

#if canImport(MachO)
public func LKGetCurrentExecutableUrl() -> URL {
    func imp(bufsize: UInt32) -> String {
        var bufsize = bufsize
        let buffer = UnsafeMutablePointer<Int8>.allocate(capacity: Int(bufsize))
        buffer.initialize(repeating: 0, count: Int(bufsize))
        defer { buffer.deallocate() }
        
        switch _NSGetExecutablePath(buffer, &bufsize) {
        case 0: // success
            return String(cString: buffer)
        case -1: // error: buffer too small
            return imp(bufsize: bufsize)
        default:
            fatalError("unreachable") // https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/dyld.3.html
        }
    }
    return URL(fileURLWithPath: imp(bufsize: 512))
}
#else
public func LKGetCurrentExecutableUrl() -> URL {
    //class BundleLocator {}
    return Bundle.main.executableURL!
}
#endif

