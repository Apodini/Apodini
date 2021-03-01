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


/// Checks if the parameter is a POSIX error code indiating a failire, and, if yes, throws an appropriate error
public func throwIfPosixError(_ posixErrno: Int32) throws {
    guard posixErrno != 0 else {
        return
    }
    throw NSError(domain: NSPOSIXErrorDomain, code: Int(posixErrno), userInfo: [
        NSLocalizedDescriptionKey: getErrnoString() ?? ""
    ])
}


/// Returns a string representation of the current `errno` value.
public func getErrnoString() -> String? {
    if let cString = strerror(errno) {
        return String(cString: cString)
    } else {
        return nil
    }
}


extension ProcessInfo {
    /// URL of the executable of the process
    public var executableUrl: URL {
        #if canImport(MachO)
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
        #else
        return Bundle.main.executableURL! // swiftlint:disable:this force_unwrapping
        #endif
    }
}
