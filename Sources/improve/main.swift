import Foundation

func usage() -> Never {
    print("usage: improve [-h|-c] <file>.imp")
    exit(-1)
}

struct Options {
    enum Mode {
        case showCFG
        case printHornClauses
        case verify
    }
    let mode: Mode
    let file: URL

    static func parseArgs() -> Options {
        guard CommandLine.arguments.count > 1 else { usage() }
        var set  = Set(CommandLine.arguments.dropFirst())
        let mode: Mode
        if set.remove("-h") != nil {
            mode = .printHornClauses
        } else if set.remove("-c") != nil {
            mode = .showCFG
        } else {
            mode = .verify
        }
        guard set.count == 1 else { usage() }
        return Options(mode: mode, file: URL(fileURLWithPath: set.first!))
    }
}

func main() throws {
    let options = Options.parseArgs()
    let input = try String(contentsOf: options.file, encoding: .utf8)
    let lexer = Lexer(input: input, filename: options.file.path)
    let parser = Parser(tokens: lexer.lex())
    let stmt = try parser.parseStmt()
    switch options.mode {
    case .showCFG:
        let cfg = CFGNode.program(stmt)
        try DOT.serializeCFG(cfg, file: options.file)
    case .printHornClauses:
        fatalError("unimplemented")
    case .verify:
        fatalError("unimplemented")
    }
}

do {
    try main()
} catch {
    print("error: \(error)")
}
