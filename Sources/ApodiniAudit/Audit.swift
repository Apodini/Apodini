//
//  File.swift
//  
//
//  Created by Simon Bohnen on 3/21/22.
//

import Foundation
import Apodini

public class Audit {
    public static func audit<H: Handler>(_ app: Application, _ endpoint: Endpoint<H>) {
        // Audit the given endpoint.
        // Iterate over all best practices.
        // figure out which ones are silenced for the current endpoint
        AppropriateLengthForURLPathSegments().check(app, endpoint)
    }
}
