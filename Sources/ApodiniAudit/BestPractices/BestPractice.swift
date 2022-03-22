//
//  File.swift
//  
//
//  Created by Simon Bohnen on 3/21/22.
//

import Foundation
import Apodini

protocol BestPractice {
    func check<H: Handler>(_ endpoint: Endpoint<H>)
}
