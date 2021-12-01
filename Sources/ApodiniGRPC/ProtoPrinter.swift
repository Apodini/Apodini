import Foundation
import ProtobufferCoding


extension ProtoPrinter {
    static func print(_ descriptor: FileDescriptorProto) -> String {
        var printer = ProtoPrinter(indentWidth: 2)
        printer.print(descriptor)
        return printer.finalise()
    }
}



// MARK: Helper Protocols
// Protocols to unify the handling of descriptor types

private protocol ProtoDescriptorReservedRangeType {
    var start: Int32? { get }
    var end: Int32? { get }
}

private protocol ProtoDescriptorWithReservedRangesAndNames {
    associatedtype ReservedRangeType: ProtoDescriptorReservedRangeType
    var reservedRanges: [ReservedRangeType] { get }
    var reservedNames: [String] { get }
}

extension DescriptorProto.ReservedRange: ProtoDescriptorReservedRangeType {}
extension EnumDescriptorProto.EnumReservedRange: ProtoDescriptorReservedRangeType {}
extension DescriptorProto: ProtoDescriptorWithReservedRangesAndNames {}
extension EnumDescriptorProto: ProtoDescriptorWithReservedRangesAndNames {}


// MARK: ProtoPrinter implementation

struct ProtoPrinter {
    private var text: String = ""
    private var indentLevel: UInt = 0
    private let indentWidth: UInt8
    
    /// The proto file descriptor currently being printed
    private var fileDescriptor: FileDescriptorProto?
    
    private init(indentWidth: UInt8 = 2) {
        self.indentWidth = indentWidth
    }
    
    
    mutating fileprivate func indent() {
        indentLevel += 1
    }
    
    mutating fileprivate func outdent() {
        indentLevel -= 1
    }
    
    private func makeIndentString() -> String {
        String(repeating: " ", count: Int(indentWidth) * Int(indentLevel))
    }
    
    mutating fileprivate func write(_ newText: String) {
        // Note that we're intentionally using .components(separatedBy:) instead split(separator:),
        // the reason being that the first will produce empty strings for adjacent newlines or newlines
        // at the beginning/end of the input, while the latter will not.
        let lines = newText.components(separatedBy: .newlines)
        for (idx, line) in lines.enumerated() {
            if (self.text.isEmpty || self.text.hasSuffix("\n")) && !(line.isEmpty && idx == lines.endIndex - 1) {
                self.text.append(makeIndentString())
            }
            self.text.append(contentsOf: line)
            if idx < lines.endIndex - 1 {
                newline()
                //self.text.append(makeIndentString())
            }
        }
    }
    
    mutating fileprivate func newline(_ count: UInt = 1) {
        for _ in 0..<count {
            text.append("\n")
        }
    }
    
    mutating fileprivate func finalise() -> String {
        precondition(indentLevel == 0)
        if !text.hasSuffix("\n") {
            newline()
        }
        return text
    }
    
    
    mutating fileprivate func print(_ descriptor: FileDescriptorProto) {
        self.fileDescriptor = descriptor
        
        write("// \(descriptor.name)\n")
        write("//\n")
        let fmt = ISO8601DateFormatter()
        fmt.timeZone = .current
        fmt.formatOptions = [.withFullDate, .withFullTime, .withTimeZone, .withSpaceBetweenDateAndTime]
        write("// Auto-generated by ApodiniGRPC, at \(fmt.string(from: Date()))\n")
        newline(3)
        write("syntax = \"\(descriptor.syntax)\";\n")
        newline()
        write("package \(descriptor.package);\n")
        
        if !descriptor.dependencies.isEmpty {
            newline(2)
            for dependency in descriptor.dependencies {
                write("import \"\(dependency)\";\n")
            }
        }
        
        newline(2)
        
        for service in descriptor.services.sorted(by: \.name) {
            self.print(service)
            newline(2)
        }
        
        for messageType in descriptor.messageTypes.sorted(by: \.name) {
            self.print(messageType)
            newline(2)
        }
        
        for enumType in descriptor.enumTypes.sorted(by: \.name) {
            self.print(enumType)
            newline(2)
        }
    }
    
    
    mutating private func print(_ descriptor: DescriptorProto) {
        write("message \(descriptor.name) {\n")
        indent()
        for field in descriptor.fields.sorted(by: \.name) {
            print(field)
        }
        
        for messageType in descriptor.nestedTypes.sorted(by: \.name) {
            print(messageType)
        }
        // TODO newlines around here!
        
        for enumType in descriptor.enumTypes.sorted(by: \.name) {
            print(enumType) // TODO do we need to adjust the typename here? prob not, right? since its already nested?
        }
        
        printReservedFieldsInfo(descriptor)
        outdent()
        write("}\n")
    }
    
    
    mutating private func print(_ descriptor: FieldDescriptorProto) {
        switch descriptor.label {
        case nil:
            break
        case .LABEL_OPTIONAL:
            write("optional ")
        case .LABEL_REPEATED:
            write("repeated ")
        case .LABEL_REQUIRED:
            precondition(self.fileDescriptor!.syntax == "proto2")
            write("required ")
        }
        
        switch descriptor.type {
        case nil:
            fatalError()
        case .TYPE_DOUBLE:
            write("double ")
        case .TYPE_FLOAT:
            write("float ")
        case .TYPE_INT64:
            write("int64 ")
        case .TYPE_UINT64:
            write("uint64 ")
        case .TYPE_INT32:
            write("int32 ")
        case .TYPE_FIXED64:
            write("fixed64 ")
        case .TYPE_FIXED32:
            write("fixed32 ")
        case .TYPE_BOOL:
            write("bool ")
        case .TYPE_STRING:
            write("string ")
        case .TYPE_GROUP:
            fatalError()
        case .TYPE_MESSAGE, .TYPE_ENUM:
            write("\(descriptor.typename!) ")
        case .TYPE_BYTES:
            write("bytes ")
        case .TYPE_UINT32:
            write("uint32 ")
        case .TYPE_SFIXED32:
            write("sfixed32 ")
        case .TYPE_SFIXED64:
            write("sfixed64 ")
        case .TYPE_SINT32:
            write("sint32 ")
        case .TYPE_SINT64:
            write("sint64 ")
        }
        write("\(descriptor.name) = \(descriptor.number)") // TODO default values? packed encoding?
        if let options = descriptor.options, descriptor.label == .LABEL_REPEATED {
            // we currently only support the packed option, on fields w/ a repeated type.
            write(" [packed = \(options.packed))];")
        } else {
            write(";")
        }
        newline()
    }
    
    
    mutating private func print(_ descriptor: EnumDescriptorProto) {
        write("enum \(descriptor.name) {\n")
        indent()
        for enumCase in descriptor.values.sorted(by: \.number) {
            write("\(enumCase.name) = \(enumCase.number);") // TODO options?!!!
            newline()
        }
        printReservedFieldsInfo(descriptor)
        outdent()
        write("}")
        newline()
    }
    
    
    mutating private func printReservedFieldsInfo<T: ProtoDescriptorWithReservedRangesAndNames>(_ descriptor: T) {
        guard !descriptor.reservedRanges.isEmpty || !descriptor.reservedNames.isEmpty else {
            return
            
        }
        newline()
        if !descriptor.reservedRanges.isEmpty {
            let rangesText = descriptor.reservedRanges.compactMap { range in
                switch (range.start, range.end) {
                case (nil, nil):
                    return nil
                case (.some(let value), nil), (nil, .some(let value)):
                    return String(value)
                case let (.some(start), .some(end)):
                    if start == end {
                        return String(start)
                    } else {
                        return "\(start) to \(end)"
                    }
                }
            }.joined(separator: ", ")
            if !rangesText.isEmpty {
                write("reserved \(rangesText);")
                newline()
            }
        }
        if !descriptor.reservedNames.isEmpty {
            let namesText = descriptor.reservedNames
                .map { "\"\($0)\"" }
                .joined(separator: ", ")
            write("reserved \(namesText);")
            newline()
        }
    }
    
    
    mutating private func print(_ descriptor: ServiceDescriptorProto) {
        write("service \(descriptor.name) {\n")
        indent()
        for method in descriptor.methods.sorted(by: \.name) {
            print(method)
        }
        outdent()
        write("}")
        newline()
    }
    
    
    mutating private func print(_ descriptor: MethodDescriptorProto) {
        write("rpc ")
        write(descriptor.name)
        write("(")
        if descriptor.clientStreaming {
            write("stream ")
        }
        write(descriptor.inputType)
        write(") returns (")
        if descriptor.serverStreaming {
            write("stream ")
        }
        write(descriptor.outputType)
        write(");")
        newline()
    }
}



//extension FieldDescriptorProto.FieldType {
//    var printableTypename
//}
