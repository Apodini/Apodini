//
//  User.swift
//  
//
//  Created by Paul Schmiedmayer on 1/19/21.
//

import Foundation
import Apodini


struct User: Content, Identifiable, WithRelationships {
    var id: Int
    var writtenId = UUID()

    static var relationships: Relationships {
        References<Post>(as: "written", at: \.writtenId)
    }
}
