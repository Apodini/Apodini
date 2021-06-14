//
//  HTTPStatus+Status.swift
//  
//
//  Created by Paul Schmiedmayer on 5/26/21.
//

import Apodini
import Vapor


extension Vapor.HTTPStatus {
    public init(_ status: Apodini.Status) {
        switch status {
        case .ok:
            self = .ok
        case .created:
            self = .created
        case .noContent:
            self = .noContent
        case .redirect:
            self = .seeOther
        }
    }
}
