//
// Created by Andreas Bauer on 22.01.21.
//

import Foundation
import Apodini

struct Post: Content, Identifiable {
    var id: UUID
    var title: String
}
