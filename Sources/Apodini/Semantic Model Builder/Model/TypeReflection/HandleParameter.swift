//
//  File.swift
//  
//
//  Created by Nityananda on 12.01.21.
//

func handleParameter(_ node: Node<EnrichedInfo>) throws -> Tree<EnrichedInfo> {
    #warning("Replace Never with Parameter<T>...")
    guard node.value.typeInfo.type == Never.self,
          let first = node.value.typeInfo.genericTypes.first else {
              return node
          }
    
    let newNode = try EnrichedInfo.node(first)
    
    let newEnrichedInfo = EnrichedInfo(
        typeInfo: newNode.value.typeInfo,
        propertyInfo: node.value.propertyInfo.map {
            PropertyInfo(
                name: String($0.name.dropFirst()),
                offset: $0.offset
            )
        }
    )

    return Node(value: newEnrichedInfo, children: newNode.children)
}
