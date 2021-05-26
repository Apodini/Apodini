//
//  HTTPStatus+Status.swift
//  
//
//  Created by Paul Schmiedmayer on 5/26/21.
//

import Apodini
import Vapor

extension Vapor.HTTPStatus {
    init(_ status: Apodini.Status) {
        switch status {
        case .ok:
            self = .ok
        case .created:
            self = .created
        case .noContent:
            self = .noContent
        }
    }
}
