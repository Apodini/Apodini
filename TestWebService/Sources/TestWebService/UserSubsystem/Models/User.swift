//
//  User.swift
//  
//
//  Created by Paul Schmiedmayer on 1/19/21.
//

import Foundation
import Apodini


struct User: Content, Identifiable {
    var id: Int
    var writtenId = UUID()

    static var metadata: Metadata {
        References<Post>(as: "written", identifiedBy: \.writtenId)
    }
}
