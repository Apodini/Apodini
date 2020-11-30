//
//  File.swift
//  
//
//  Created by Alexander Collins on 14.11.20.
//

import Foundation
import Vapor


public struct Device: Content {
    public var type: DeviceType
    public var deviceID: String
    public var topics: [String]?
}

public enum DeviceType: String {
    case apns
    case fcm
}

extension DeviceType: Content { }
