indirect enum LogicPiece: CustomStringConvertible {
    case predicate(String, Set<String>)
    case assumption(BExp)
    case conjunction(LogicPiece, LogicPiece)

    var description: String {
        switch self {
        case .assumption(let bexp):
            return "\(bexp)"
        case let .conjunction(lhs, rhs):
            return "\(lhs) ^ \(rhs)"
        case let .predicate(name, args):
            return "\(name)(\(args.sorted().joined(separator: ", ")))"
        }
    }
}

struct HornClause {
    let condition: LogicPiece
    let result: LogicPiece
}

class HornClauseGenerator {
    var clauseCounter = 0
    var clauses = [HornClause]()
    var visited = Set<CFGNode>()
    var nodeLabels = [CFGNode: String]()
    let variables: Set<String>
    let root: CFGNode

    init(stmt: Stmt) {
        self.root = CFGNode.program(stmt)
        self.variables = HornClauseGenerator.variables(in: stmt)
    }

    func freshLabel() -> String {
        defer { clauseCounter += 1 }
        return "P\(clauseCounter)"
    }

    func label(for node: CFGNode) -> String {
        if let label = nodeLabels[node] { return label }
        let label = freshLabel()
        nodeLabels[node] = label
        return label
    }

    func addClause(_ condition: LogicPiece, _ result: LogicPiece) {
        clauses.append(HornClause(condition: condition, result: result))
    }

    func addClause(_ condition: LogicPiece, _ node: CFGNode) {
        addClause(condition, predicate(for: node))
    }

    static func variables(in exp: BExp) -> Set<String> {
        switch exp {
        case .false, .true: return []
        case let .and(lhs, rhs),
             let .or(lhs, rhs):
            return variables(in: lhs).union(variables(in: rhs))
        case let .lte(lhs, rhs),
             let .eq(lhs, rhs):
            return variables(in: lhs).union(variables(in: rhs))
        case let .not(exp): return variables(in: exp)
        }
    }

    static func variables(in exp: IExp) -> Set<String> {
        switch exp {
        case let .identifier(name): return [name]
        case let .plus(lhs, rhs),
             let .minus(lhs, rhs):
            return variables(in: lhs).union(variables(in: rhs))
        case .num(_): return []
        }
    }

    static func variables(in stmt: Stmt) -> Set<String> {
        switch stmt {
        case .skip: return []
        case let .assign(name, iexp):
            var underlying = variables(in: iexp)
            underlying.insert(name)
            return underlying
        case let .seq(lhs, rhs):
            return variables(in: lhs).union(variables(in: rhs))
        case let .assert(bexp):
            return variables(in: bexp)
        case let .conditional(cond, conseq, alter):
            return variables(in: cond)
                    .union(variables(in: conseq))
                    .union(variables(in: alter))
        case let .loop(cond, stmt):
            return variables(in: cond)
                    .union(variables(in: stmt))
        }
    }

    func predicate(for node: CFGNode) -> LogicPiece {
        return .predicate(label(for: node), variables)
    }

    func generate() {
        // The trivial implication for the entry node.
        addClause(.assumption(.true), root)
        visited.insert(root)

        for child in root.successors {
            generateChild(parent: root, child)
        }
    }

    func rename(_ name: String, in exp: BExp) -> BExp {
        switch exp {
        case let .and(lhs, rhs):
            return .and(rename(name, in: lhs), rename(name, in: rhs))
        case let .or(lhs, rhs):
            return .or(rename(name, in: lhs), rename(name, in: rhs))
        case let .lte(lhs, rhs):
            return .lte(rename(name, in: lhs), rename(name, in: rhs))
        case let .eq(lhs, rhs):
            return .eq(rename(name, in: lhs), rename(name, in: rhs))
        case let .not(exp):
            return .not(rename(name, in: exp))
        case .true:
            return .true
        case .false:
            return .false
        }
    }

    func rename(_ name: String, in exp: IExp) -> IExp {
        switch exp {
        case let .identifier(id):
            if id == name { return .identifier("\(id)Prime") }
        case let .minus(lhs, rhs):
            return .minus(rename(name, in: lhs), rename(name, in: rhs))
        case let .plus(lhs, rhs):
            return .plus(rename(name, in: lhs), rename(name, in: rhs))
        case .num(_): break
        }
        return exp
    }

    func rename(_ name: String, in pred: LogicPiece) -> LogicPiece {
        switch pred {
        case let .assumption(exp):
            return .assumption(rename(name, in: exp))
        case let .conjunction(lhs, rhs):
            return .conjunction(rename(name, in: lhs), rename(name, in: rhs))
        case let .predicate(pName, vars):
            var vs = vars
            if vs.remove(name) != nil {
                vs.insert("\(name)Prime")
            }
            return .predicate(pName, vs)
        }
    }

    func generateChild(parent: CFGNode, _ transition: CFGNode.Transition) {
        if visited.contains(transition.node) { return }
        visited.insert(transition.node)
        let parentPred = predicate(for: parent)
        var pred = predicate(for: transition.node)
        if var assumption = transition.assumption {
            if case .assign(let name, _)? = transition.node.stmt {
                assumption = rename(name, in: assumption)
                pred = rename(name, in: pred)
            }
            addClause(.conjunction(parentPred, .assumption(assumption)), pred)
        } else {
            addClause(parentPred, pred)
        }
        switch transition.node.kind {
        case .error:
            addClause(pred, .assumption(.false))
        case .exit:
            addClause(pred, .assumption(.true))
        default:
            break
        }
        for child in transition.node.successors {
            generateChild(parent: transition.node, child)
        }
    }

    func dump() {
        for clause in clauses {
            print("\(clause.condition) -> \(clause.result)")
        }
    }
}
