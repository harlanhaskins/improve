indirect enum IExp {
    // integer literal
    case num(Int)

    // [a-zA-Z_][0-9a-zA-Z_]*
    case identifier(String)

    // <iexp> + <iexp>
    case plus(Node<IExp>, Node<IExp>)

    // <iexp> - <iexp>
    case minus(Node<IExp>, Node<IExp>)
}

struct Node<T> {
    let kind: T
    let range: SourceRange?

    init(kind: T, range: SourceRange? = nil) {
        self.kind = kind
        self.range = range
    }
}

indirect enum BExp {
    // <iexp> <= <iexp>
    case lte(Node<IExp>, Node<IExp>)

    // <iexp> == <iexp>
    case eq(Node<IExp>, Node<IExp>)

    // not <bexp>
    case not(Node<BExp>)

    // <bexp> and <bexp>
    case and(Node<BExp>, Node<BExp>)

    // <bexp> or <bexp>
    case or(Node<BExp>, Node<BExp>)
}

indirect enum Stmt {
    case skip
    // <id> := <iexp>
    case assign(String, Node<IExp>)

    // <stmt> ; <stmt>
    case seq(Node<Stmt>, Node<Stmt>)

    // if (<bexp>) <stmt> else <stmt>
    case conditional(Node<BExp>, Node<Stmt>, Node<Stmt>)

    // while (<bexp>) <stmt>
    case loop(Node<BExp>, Node<Stmt>)

    // assert(<bexp>)
    case assert(Node<BExp>)
}

