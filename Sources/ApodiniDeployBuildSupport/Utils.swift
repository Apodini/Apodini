//
//  File.swift
//  
//
//  Created by Lukas Kollmer on 2021-01-01.
//

import Foundation
#if canImport(MachO)
import MachO
#endif




public class Box<T> {
    public var value: T
    
    public init(_ value: T) {
        self.value = value
    }
}


extension RandomAccessCollection {
    /// Safely access the element at the specified index.
    /// - returns: the element at `idx`, if `idx` is a valid index for subscripting into the collection, otherwise `nil`.
    public subscript(lk_safe idx: Index) -> Element? {
        indices.contains(idx) ? self[idx] : nil
    }
}




extension Collection {
    /// Count the number of elements matching `predicate`
    public func lk_count(where predicate: (Element) throws -> Bool) rethrows -> Int {
        try reduce(into: 0) { $0 += try predicate($1) ? 1 : 0 }
    }
    
    
    /// Returns the first element after the specified index, which matches the predicate
    public func lk_first(after idx: Index, where predicate: (Element) throws -> Bool) rethrows -> Element? {
        return try lk_firstIndex(from: index(after: idx), where: predicate).map { self[$0] }
    }
    
    
    public func lk_firstIndex(after idx: Index, where predicate: (Element) throws -> Bool) rethrows -> Index? {
        return try lk_firstIndex(from: index(after: idx), where: predicate)
    }
    
    /// Returns the first index within the collection which matches a predicate, starting at `from`.
    public func lk_firstIndex(from idx: Index, where predicate: (Element) throws -> Bool) rethrows -> Index? {
        guard indices.contains(idx) else {
            return nil
        }
        if try predicate(self[idx]) {
            return idx
        } else {
            return try lk_firstIndex(from: index(after: idx), where: predicate)
        }
    }
}




// MARK: Other


func throwIfPosixError(_ posixErrno: Int32) throws {
    guard posixErrno != 0 else { return }
    throw NSError(domain: NSPOSIXErrorDomain, code: Int(posixErrno), userInfo: [
        NSLocalizedDescriptionKey: getErrnoString() ?? ""
    ])
}


private func getErrnoString() -> String? {
    if let cString = strerror(errno) {
        return String(cString: cString)
    } else {
        return nil
    }
}


extension ProcessInfo {
    /// The group id of the current process
    var lk_groupId: pid_t { getpgrp() }
    
    /// The process id of the current process's parent
    var lk_parentProcessId: pid_t { getppid() }
    
    /// The group id of the current process's parent
    var lk_parentGroupId: pid_t { getpgid(lk_parentProcessId) }
}


//precondition(URL(fileURLWithPath: ProcessInfo.processInfo.arguments[0]) == Bundle(for: Self.self).executableURL!)

#if false || canImport(MachO)
func LKGetCurrentExecutableUrl() -> URL {
    func imp(bufsize: UInt32) -> String {
        var bufsize = bufsize
        let buffer = UnsafeMutablePointer<Int8>.allocate(capacity: Int(bufsize))
        buffer.initialize(repeating: 0, count: Int(bufsize))
        
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
func LKGetCurrentExecutableUrl() -> URL {
    //class BundleLocator {}
    return Bundle.main.executableURL!
}
#endif





