enum ParseError: Error {
    case expectedIExp
    case expectedBExp
    case expectedStmt
    case unexpected(Token, expected: String)
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

    @discardableResult
    func consume(_ kind: Token) throws -> Token {
        guard let tok = currentToken else { throw ParseError.unexpectedEOF }
        guard tok == kind else {
            throw ParseError.unexpected(tok, expected: "\(kind)")
        }
        advance()
        return tok
    }

    func parseStmt() throws -> Stmt {
        guard let tok = currentToken else { throw ParseError.unexpectedEOF }
        let lhs: Stmt
        switch tok {
        case .skip:
            advance()
            lhs = .skip
        case .identifier(_):
            lhs = try parseAssign()
        case .if:
            lhs = try parseIf()
        case .while:
            lhs = try parseWhile()
        case .assert:
            lhs = try parseAssert()
        default:
            throw ParseError.unexpected(tok, expected: "statement")
        }
        if case .semicolon? = currentToken {
            advance()
            if currentToken == nil {
                return lhs
            }
            let rhs = try parseStmt()
            return .seq(lhs, rhs)
        }
        return lhs
    }

    func parseAssign() throws -> Stmt {
        guard let tok = currentToken else { throw ParseError.unexpectedEOF }
        guard case .identifier(let name) = tok else {
            throw ParseError.unexpected(tok, expected: "identifier")
        }
        advance()
        try consume(.assignEq)
        let rhs = try parseIExp()
        return .assign(name, rhs)
    }

    func parseIf() throws -> Stmt {
        try consume(.if)
        try consume(.leftParen)
        let cond = try parseBExp()
        try consume(.rightParen)
        let body = try parseStmt()
        try consume(.else)
        let elseStmt = try parseStmt()
        try consume(.endif)
        return .conditional(cond, body, elseStmt)
    }

    func parseWhile() throws -> Stmt {
        try consume(.while)
        try consume(.leftParen)
        let cond = try parseBExp()
        try consume(.rightParen)
        let body = try parseStmt()
        try consume(.endwhile)
        return .loop(cond, body)
    }

    func parseAssert() throws -> Stmt {
        try consume(.assert)
        try consume(.leftParen)
        let cond = try parseBExp()
        try consume(.rightParen)
        return .assert(cond)
    }

    func parseBExp() throws -> BExp {
        guard let tok = currentToken else { throw ParseError.unexpectedEOF }
        let lhs: BExp
        if isStartOfIExp() {
            let lhsIExp = try parseIExp()
            guard let infixTok = currentToken else { throw ParseError.unexpectedEOF }
            switch infixTok {
            case .lte:
                advance()
                let rhsIExp = try parseIExp()
                lhs = .lte(lhsIExp, rhsIExp)
            case .eq:
                advance()
                let rhsIExp = try parseIExp()
                lhs = .eq(lhsIExp, rhsIExp)
            default:
                throw ParseError.unexpected(infixTok, expected: "boolean operator")
            }
        } else if case .not = tok {
            advance()
            let rhs = try parseBExp()
            lhs = .not(rhs)
        } else {
            throw ParseError.unexpected(tok, expected: "boolean expression")
        }
        switch currentToken {
        case .and?:
            advance()
            let rhs = try parseBExp()
            return .and(lhs, rhs)
        case .or?:
            advance()
            let rhs = try parseBExp()
            return .or(lhs, rhs)
        default:
            return lhs
        }
    }

    func isStartOfIExp() -> Bool {
        switch currentToken {
        case .integer?, .identifier?: return true
        default: return false
        }
    }

    func parseIExp() throws -> IExp {
        guard let tok = currentToken else {
            throw ParseError.unexpectedEOF
        }
        let lhs: IExp
        switch tok {
        case .integer(let intVal):
            advance()
            lhs = .num(intVal)
        case .identifier(let id):
            advance()
            lhs = .identifier(id)
        default:
            throw ParseError.unexpected(tok, expected: "expression")
        }
        switch currentToken {
        case .plus?:
            advance()
            let rhs = try parseIExp()
            return .plus(lhs, rhs)
        case .minus?:
            advance()
            let rhs = try parseIExp()
            return .minus(lhs, rhs)
        default:
            return lhs
        }
    }
}
