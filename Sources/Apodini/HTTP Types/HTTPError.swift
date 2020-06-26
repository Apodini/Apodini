//
//  HTTPError.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//


public enum HTTPError: Error {
    case ok
    case notImplemented
    case internalServerError(reason: String)
}
