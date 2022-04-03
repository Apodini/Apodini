//
//  File.swift
//  
//
//  Created by Simon Bohnen on 3/21/22.
//

import Foundation
import Apodini

struct AppropriateLengthForURLPathSegments: BestPractice {
    func check<H: Handler>(_ app: Application, _ endpoint: Endpoint<H>) {
        // Go through all the path segments
        for segment in endpoint.absolutePath {
            if case .string(let identifier) = segment {
                app.logger.info("\(identifier)")
            }
        }
    }
}
