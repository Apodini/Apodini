//
//  File.swift
//  
//
//  Created by Simon Bohnen on 3/21/22.
//

import Foundation
import Apodini

struct AppropriateLengthForURLPathSegments: BestPractice {
    func check<H: Handler>(_ endpoint: Endpoint<H>) {
        print(endpoint.absolutePath[0])
    }
}
