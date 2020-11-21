//
//  APNSConfiguration.swift
//  
//
//  Created by Alexander Collins on 18.11.20.
//
import Vapor

public struct APNSConfiguration: Configuration {
    
    private let text: String
    
    
    public init(_ text: String) {
        self.text = text
    }
    
    public func configure(_ app: Application) -> String {
        print(text)
        return text
    }
}
