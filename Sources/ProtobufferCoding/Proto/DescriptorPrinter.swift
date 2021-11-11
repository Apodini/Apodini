
//extension FileDescriptorSet {
//    public func toString() -> String {
//
//    }
//}
//
//
//
//private struct DescriptorPrinter {
//    // config
//    let indentWidth: Int
//
//    // state
//    private var text: String = ""
//    private var indentLevel: Int = 0
//
//
//    mutating func indent() {
//        indentLevel += 1
//    }
//
//    mutating func outdent() { // TODO is this the correct opposite?
//        indentLevel -= 1
//    }
//
//    mutating func printIndent() {
//        text += String(repeating: " ", count: indentWidth * indentLevel)
//    }
//
//    mutating func write(_ text: String) {
//        let lines = text.split(separator: "\n")
//        if lines.count == 1 {
//            self.text.append(text)
//        } else {
//            for (idx, line) in lines.enumerated() {
//                if idx != 0 {
//                    printIndent()
//                }
//                text += line
//            }
//        }
//    }
//
//}
//
//
//protocol PrintableProtoDescriptor {
//    func print(to printer: inout DescriptorPrinter)
//}
//
//
//
//extension FileDescriptorSet: PrintableProtoDescriptor {
//    func print(to printer: inout DescriptorPrinter) {
//        <#code#>
//    }
//}
