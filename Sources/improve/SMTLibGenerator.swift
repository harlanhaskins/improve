struct SMTLibGenerator {
    let clauses: [HornClause]
    let variables: Set<String>

    func call(_ fnName: String, _ args: String...) -> String {
        return call(fnName, args)
    }

    func call(_ fnName: String, _ args: [String]) -> String {
        return "(\(fnName) \(args.joined(separator: " ")))"
    }

    func toSMTLib(_ exp: IExp) -> String {
        switch exp {
        case let .identifier(id): return id
        case let .num(n): return n.description
        case let .minus(lhs, rhs):
            return call("-", toSMTLib(lhs), toSMTLib(rhs))
        case let .plus(lhs, rhs):
            return call("+", toSMTLib(lhs), toSMTLib(rhs))
        }
    }

    func toSMTLib(_ exp: BExp) -> String {
        switch exp {
        case let .and(lhs, rhs):
            return call("and", toSMTLib(lhs), toSMTLib(rhs))
        case let .or(lhs, rhs):
            return call("or", toSMTLib(lhs), toSMTLib(rhs))
        case let .lte(lhs, rhs):
            return call("<=", toSMTLib(lhs), toSMTLib(rhs))
        case let .eq(lhs, rhs):
            return call("=", toSMTLib(lhs), toSMTLib(rhs))
        case let .not(rhs):
            return call("not", toSMTLib(rhs))
        case .false: return "false"
        case .true: return "true"
        }
    }

    func toSMTLib(_ piece: LogicPiece) -> String {
        switch piece {
        case let .assumption(exp):
            return toSMTLib(exp)
        case let .conjunction(lhs, rhs):
            return call("and", toSMTLib(lhs), toSMTLib(rhs))
        case let .predicate(name, vars):
            return call(name, vars.sorted())
        }
    }

    func variables(in logicPiece: LogicPiece) -> Set<String> {
        switch logicPiece {
        case .assumption(_): return []
        case let .conjunction(lhs, rhs):
            return variables(in: lhs).union(variables(in: rhs))
        case let .predicate(_, vars):
            return vars
        }
    }

    func assertion(_ clause: HornClause) -> String {
        let totalVars = variables(in: clause.result).union(variables(in: clause.condition))
        let varNames = totalVars.map { "(\($0) Int)" }.joined(separator: " ")
        return call("assert",
                    call("forall",
                         "(\(varNames))",
                         call("=>",
                              toSMTLib(clause.condition),
                              toSMTLib(clause.result))))
    }

    func declareFun(_ function: (String, Int)) -> String {
        let typeNames = [String](repeating: "Int", count: function.1)
        let typeList = typeNames.joined(separator: " ")
        return call("declare-fun", function.0, "(\(typeList))", "Bool")
    }

    func makeSMTLib() -> String {
        var functions = [String: Int]()
        var assertions = [String]()
        for clause in clauses {
            if case let .predicate(name, vars) = clause.result {
                functions[name] = vars.count
            }
            if case let .predicate(name, vars) = clause.condition {
                functions[name] = vars.count
            }
            assertions.append(assertion(clause))
        }
        return """
        (set-option :print-success false)
        (set-logic HORN)
        \(functions.map { declareFun($0) }.joined(separator: "\n"))
        \(assertions.joined(separator: "\n"))
        (check-sat)
        """
    }
}
