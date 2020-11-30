//
//  File.swift
//  
//
//  Created by Alexander Collins on 15.11.20.
//

import Foundation
import Vapor
import APNS

@propertyWrapper
public struct APNSNotification: RequestInjectable {
    private var notification: Vapor.Request.APNS?
    
    
    public var wrappedValue: Vapor.Request.APNS {
        guard let notification = notification else {
            fatalError("You can only access the notification while you handle a request")
        }
        
        return notification
    }
    
    
    public init() { }
    
    
    mutating func inject(using request: Vapor.Request, with decoder: SemanticModelBuilder? = nil) throws {
        self.notification = request.apns
    }
}
