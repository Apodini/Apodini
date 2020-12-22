//
// Created by Andi on 22.12.20.
//

protocol ApodiniEncodable: Encodable {
    func accept(_ visitor: ApodiniEncodableVisitor)
}

extension ApodiniEncodable {
    func accept(_ visitor: ApodiniEncodableVisitor) {
        visitor.visit(encodable: self)
    }
}

protocol ApodiniEncodableVisitor {
    func visit<Element: Encodable>(encodable: Element)
    func visit<Element: Encodable>(action: Action<Element>)
}
