//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation


struct EndpointInstance<H: Handler> {
    let endpoint: Endpoint<H>
    
    var handler: H
    
    init(from endpoint: Endpoint<H>) {
        self.endpoint = endpoint
        
        var handler = endpoint.handler
        
        activate(&handler)
        
        self.handler = handler
    }
}
    
