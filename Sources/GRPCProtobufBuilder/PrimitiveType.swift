//
//  File.swift
//  
//
//  Created by Nityananda on 30.11.20.
//

func isPrimitive(_ type: Any.Type) -> Bool {
    [
        Bool.self,
        Int.self,
        
        String.self,
        
        Array<Any>.self,
    ]
    .contains { (other) -> Bool in
        type == other
    }
}

func isTopLevelCompatible(_ type: Any.Type) -> Bool {
    !isPrimitive(type)
}
