import Foundation

enum Z3Result {
    case satisfiable
    case unsatisfiable
}

enum Z3Executor {
    static func runZ3(file: URL, clauses: [HornClause],
                      variables: Set<String>) throws -> Z3Result {
        let smtlibGen = SMTLibGenerator(clauses: clauses, variables: variables)
        let text = smtlibGen.makeSMTLib()
        let url = file.deletingPathExtension().appendingPathExtension("smt2")
        try text.write(to: url, atomically: true, encoding: .utf8)
        let output = run("z3", "-smt2", url.path)
        let satisfiability =
            String(data: output, encoding: .utf8)!
                .trimmingCharacters(in: .whitespacesAndNewlines)
        return satisfiability == "sat" ? .satisfiable : .unsatisfiable
    }
}
