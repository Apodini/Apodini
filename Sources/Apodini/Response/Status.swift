//
//  Status.swift
//  
//
//  Created by Paul Schmiedmayer on 2/3/21.
//

/// An `Status` expresses additional information that can be passed to a `Response`
public enum Status {
    /// The request was handled and the response contains the expected content
    case ok
    /// The request was handled and the response does not contain any content
    case noContent
}
