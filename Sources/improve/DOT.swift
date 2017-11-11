import Foundation

enum DOT {
    static func serializeCFG(_ node: CFGNode, file: URL) throws {
        let serializer = DOTCFGSerializer()
        let dot = serializer.makeDOT(node: node)
        let dotFile = file.deletingPathExtension()
                          .appendingPathExtension("dot")
        let pngFile = file.deletingPathExtension()
                          .appendingPathExtension("png")
        try dot.write(to: dotFile, atomically: true, encoding: .utf8)
        let pngContents = run("dot", "-Tpng", dotFile.path)
        try pngContents.write(to: pngFile)
        print("CFG written to \(pngFile.path)")
    }
}

class DOTCFGSerializer {
    var nodeCounter = 0
    var lines = [String]()
    var labelMap = [CFGNode: String]()
    var visited = Set<CFGNode>()

    func freshLabel() -> String {
        defer { nodeCounter += 1 }
        return "e\(nodeCounter)"
    }

    func label(for node: CFGNode) -> String {
        if let label = labelMap[node] { return label }
        let label = freshLabel()
        labelMap[node] = label
        return label
    }
    
    func color(for nodeKind: CFGNode.Kind) -> String? {
        switch nodeKind {
        case .error: return "red"
        case .exit: return "green"
        default: return nil
        }
    }

    func makeDOTImpl(node: CFGNode) {
        if visited.contains(node) { return }
        visited.insert(node)
        if let color = color(for: node.kind) {
            lines.append("  \(label(for: node)) [color=\(color)];")
        }
        for succ in node.successors {
            var line = "  \(label(for: node)) -> \(label(for: succ.node))"
            if let assumption = succ.assumption {
                line += " [label=\" \(assumption)  \"]"
            }
            lines.append(line + ";")
            makeDOTImpl(node: succ.node)
        }
    }

    func makeDOT(node: CFGNode) -> String {
        lines.append("digraph CFG {")
        makeDOTImpl(node: node)
        lines.append("}")
        return lines.joined(separator: "\n")
    }
}
