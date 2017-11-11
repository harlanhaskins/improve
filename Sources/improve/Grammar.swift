indirect enum IExp: CustomStringConvertible {
    // integer literal
    case num(Int)

    // [a-zA-Z_][0-9a-zA-Z_]*
    case identifier(String)

    // <iexp> + <iexp>
    case plus(IExp, IExp)

    // <iexp> - <iexp>
    case minus(IExp, IExp)

    var description: String {
        switch self {
        case let .identifier(name): return name
        case let .num(i): return i.description
        case let .plus(e1, e2): return "\(e1) + \(e2)"
        case let .minus(e1, e2): return "\(e1) - \(e2)"
        }
    }
}

indirect enum BExp: CustomStringConvertible {
    // Not spellable in the language
    case `true`
    case `false`

    // <iexp> <= <iexp>
    case lte(IExp, IExp)

    // <iexp> == <iexp>
    case eq(IExp, IExp)

    // not <bexp>
    case not(BExp)

    // <bexp> and <bexp>
    case and(BExp, BExp)

    // <bexp> or <bexp>
    case or(BExp, BExp)

    var description: String {
        switch self {
        case .true: return "True"
        case .false: return "False"
        case let .lte(e1, e2): return "\(e1) <= \(e2)"
        case let .eq(e1, e2): return "\(e1) == \(e2)"
        case let .not(e): return "not \(e)"
        case let .and(e1, e2): return "\(e1) and \(e2)"
        case let .or(e1, e2): return "\(e1) or \(e2)"
        }
    }
}

indirect enum Stmt {
    case skip
    // <id> := <iexp>
    case assign(String, IExp)

    // <stmt> ; <stmt>
    case seq(Stmt, Stmt)

    // if (<bexp) <stmt> else <stmt>
    case conditional(BExp, Stmt, Stmt)

    // while (<bexp) <stmt>
    case loop(BExp, Stmt)

    // assert(<bexp)
    case assert(BExp)
}

