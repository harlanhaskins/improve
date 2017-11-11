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
        let clauseGen = HornClauseGenerator(stmt: stmt)
        clauseGen.generate()
        clauseGen.dump()
    case .verify:
        let clauseGen = HornClauseGenerator(stmt: stmt)
        clauseGen.generate()
        let output = try Z3Executor.runZ3(file: options.file,
                                          clauses: clauseGen.clauses,
                                          variables: clauseGen.variables)
        switch output {
        case .satisfiable:
            print("correct")
        case .unsatisfiable:
            print("incorrect")
        }
    }
}

do {
    try main()
} catch {
    print("error: \(error)")
}
