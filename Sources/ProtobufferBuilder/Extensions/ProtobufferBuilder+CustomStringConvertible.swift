//
//  File.swift
//  
//
//  Created by Nityananda on 08.12.20.
//

extension ProtobufferBuilder: CustomStringConvertible {
    public var description: String {
        let services = self.services
            .sorted(by: \.name)
            .map(\.description)
            .joined(separator: "\n\n")
        
        let messages = self.messages
            .sorted(by: \.name)
            .map(\.description)
            .joined(separator: "\n\n")
        
        let protoFile = [
            #"syntax = "proto3";"#,
            services,
            messages
        ]
        .filter { !$0.isEmpty }
        .joined(separator: "\n\n")
        
        return protoFile
    }
}
