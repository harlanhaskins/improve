enum ParseError: Error {
    case expectedIExp
    case expectedBExp
    case expectedStmt
    case unexpected(Token.Kind, expected: String)
    case unexpectedEOF
}

class Parser {
    let tokens: [Token]
    var index = 0

    init(tokens: [Token]) {
        self.tokens = tokens
    }

    var currentToken: Token? {
        return index < tokens.count ? tokens[index] : nil
    }

    func advance() {
        index += 1
    }

    func span(_ range1: SourceRange?, _ range2: SourceRange?) -> SourceRange? {
        guard let range1 = range1, let range2 = range2 else { return nil }
        return SourceRange(start: range1.start, end: range2.start)
    }

    @discardableResult
    func consume(_ kind: Token.Kind) throws -> Token {
        guard let tok = currentToken else { throw ParseError.unexpectedEOF }
        guard tok.kind == kind else {
            throw ParseError.unexpected(tok.kind, expected: "\(kind)")
        }
        advance()
        return tok
    }

    func parseStmt() throws -> Node<Stmt> {
        guard let tok = currentToken else { throw ParseError.unexpectedEOF }
        let lhs: Node<Stmt>
        switch tok.kind {
        case .skip:
            advance()
            lhs = Node(kind: .skip, range: tok.range)
        case .identifier(_):
            lhs = try parseAssign()
        case .if:
            lhs = try parseIf()
        case .while:
            lhs = try parseWhile()
        case .assert:
            lhs = try parseAssert()
        default:
            throw ParseError.unexpected(tok.kind, expected: "statement")
        }
        if case .semicolon? = currentToken?.kind {
            advance()
            if currentToken == nil {
                return lhs
            }
            let rhs = try parseStmt()
            return Node(kind: .seq(lhs, rhs),
                        range: span(lhs.range, rhs.range))
        }
        return lhs
    }

    func parseAssign() throws -> Node<Stmt> {
        guard let tok = currentToken else { throw ParseError.unexpectedEOF }
        guard case .identifier(let name) = tok.kind else {
            throw ParseError.unexpected(tok.kind, expected: "identifier")
        }
        try consume(.assignEq)
        let rhs = try parseIExp()
        return Node(kind: .assign(name, rhs),
                    range: span(tok.range, rhs.range))
    }

    func parseIf() throws -> Node<Stmt> {
        let ifTok = try consume(.if)
        try consume(.leftParen)
        let cond = try parseBExp()
        try consume(.rightParen)
        let body = try parseStmt()
        try consume(.else)
        let elseStmt = try parseStmt()
        return Node(kind: .conditional(cond, body, elseStmt),
                    range: span(ifTok.range, elseStmt.range))
    }

    func parseWhile() throws -> Node<Stmt> {
        let whileTok = try consume(.while)
        try consume(.leftParen)
        let cond = try parseBExp()
        try consume(.rightParen)
        let body = try parseStmt()
        return Node(kind: .loop(cond, body),
                    range: span(whileTok.range, body.range))
    }

    func parseAssert() throws -> Node<Stmt> {
        let assertTok = try consume(.assert)
        try consume(.leftParen)
        let cond = try parseBExp()
        try consume(.rightParen)
        return Node(kind: .assert(cond),
                    range: span(assertTok.range, cond.range))
    }

    func parseBExp() throws -> Node<BExp> {
        guard let tok = currentToken else { throw ParseError.unexpectedEOF }
        let lhs: Node<BExp>
        if isStartOfIExp() {
            let lhsIExp = try parseIExp()
            guard let infixTok = currentToken else { throw ParseError.unexpectedEOF }
            switch infixTok.kind {
            case .lte:
                advance()
                let rhsIExp = try parseIExp()
                lhs = Node(kind: .lte(lhsIExp, rhsIExp),
                           range: span(lhsIExp.range, rhsIExp.range))
            case .eq:
                advance()
                let rhsIExp = try parseIExp()
                lhs = Node(kind: .lte(lhsIExp, rhsIExp),
                           range: span(lhsIExp.range, rhsIExp.range))
            default:
                throw ParseError.unexpected(infixTok.kind, expected: "boolean operator")
            }
        } else if case .not = tok.kind {
            advance()
            let rhs = try parseBExp()
            lhs = Node(kind: .not(rhs),
                       range: span(tok.range, rhs.range))
        } else {
            throw ParseError.unexpected(tok.kind, expected: "boolean expression")
        }
        switch currentToken?.kind {
        case .and?:
            advance()
            let rhs = try parseBExp()
            return Node(kind: .and(lhs, rhs),
                        range: span(lhs.range, rhs.range))
        case .or?:
            advance()
            let rhs = try parseBExp()
            return Node(kind: .or(lhs, rhs),
                        range: span(lhs.range, rhs.range))
        default:
            return lhs
        }
    }

    func isStartOfIExp() -> Bool {
        switch currentToken?.kind {
        case .integer?, .identifier?: return true
        default: return false
        }
    }

    func parseIExp() throws -> Node<IExp> {
        guard let tok = currentToken else {
            throw ParseError.unexpectedEOF
        }
        let lhs: Node<IExp>
        switch tok.kind {
        case .integer(let intVal):
            advance()
            lhs = Node(kind: .num(intVal), range: tok.range)
        case .identifier(let id):
            advance()
            lhs = Node(kind: .identifier(id), range: tok.range)
        default:
            throw ParseError.unexpected(tok.kind, expected: "expression")
        }
        switch currentToken?.kind {
        case .plus?:
            advance()
            let rhs = try parseIExp()
            return Node(kind: .plus(lhs, rhs),
                        range: span(lhs.range, rhs.range))
        case .minus?:
            advance()
            let rhs = try parseIExp()
            return Node(kind: .minus(lhs, rhs),
                        range: span(lhs.range, rhs.range))
        default:
            return lhs
        }
    }
}
