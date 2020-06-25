//
//  File.swift
//  
//
//  Created by Paul Schmiedmayer on 6/24/20.
//

import Foundation

protocol ResponseMediator {
    associatedtype Response
    
    init(_ response: Response)
}

struct ResponseModifier<M: ResponseMediator>: ComponentModifier {
    typealias ModifiedComponent = Text
    typealias Content = Text
    
    init(_ type: M.Type) {}
    
    func modify(content: Text) -> Text {
        content
    }
}

// Question: How to you make this generic so I can chain multiple modifiers e.g. in the test case
extension Component where Self == Text {
    func response<M: ResponseMediator>(_ modifier: M.Type) -> some Component {
        ModifiedComponent(modifiedComponent: self,
                          modifier: ResponseModifier(M.self))
    }
}
