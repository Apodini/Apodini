//
//  File.swift
//  
//
//  Created by Nityananda on 12.01.21.
//

func handleParameter(_ node: Node<EnrichedInfo>) throws -> Tree<EnrichedInfo> {
    guard mangledName(of: node.value.typeInfo.type) == "Parameter",
          let first = node.value.typeInfo.genericTypes.first else {
              return node
          }
    
    let newNode = try EnrichedInfo.node(first)
    
    let newEnrichedInfo = EnrichedInfo(
        typeInfo: newNode.value.typeInfo,
        propertyInfo: node.value.propertyInfo.map {
            PropertyInfo(
                // Instances of property wrappers are stored in variables with a "_" prefix.
                // https://docs.swift.org/swift-book/LanguageGuide/Properties.html#ID617
                name: String($0.name.dropFirst()),
                offset: $0.offset
            )
        }
    )

    return Node(value: newEnrichedInfo, children: newNode.children)
}
