//
//  EnrichedContent+Formatter.swift
//  
//
//  Created by Paul Schmiedmayer on 5/15/21.
//

import Apodini


extension EnrichedContent {
    func formatTestRelationships(hideHidden: Bool = false) -> [String: String] {
        let formatter = TestingRelationshipFormatter(hideHidden: hideHidden)

        let links = formatRelationships(into: [:], with: formatter)
        return formatSelfRelationships(into: links, with: formatter)
    }
}
