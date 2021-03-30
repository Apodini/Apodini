//
//  File.swift
//  
//
//  Created by Eldi Cano on 21.03.21.
//

import Foundation

extension Array where Element: Hashable {
    func unique() -> Set<Element> {
        Set(self)
    }
}
