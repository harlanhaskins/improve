enum Token: Equatable {
    case identifier(String)
    case integer(Int)
    case and, or, `if`, `else`, `while`, assert, skip, not, endif, endwhile
    case semicolon, leftParen, rightParen, plus, minus, lte, eq, assignEq
    case unknown(Character)

    init(identifier: String) {
        switch identifier {
        case "and": self = .and
        case "or": self = .or
        case "if": self = .if
        case "else": self = .else
        case "while": self = .while
        case "assert": self = .assert
        case "skip": self = .skip
        case "not": self = .not
        case "endif": self = .endif
        case "endwhile": self = .endwhile
        default: self = .identifier(identifier)
        }
    }

    static func ==(lhs: Token, rhs: Token) -> Bool {
        switch (lhs, rhs) {
        case let (.identifier(lhsId), .identifier(rhsId)):
            return lhsId == rhsId
        case let (.integer(lhsInt), .integer(rhsInt)):
            return lhsInt == rhsInt
        case let (.unknown(lhsChar), .unknown(rhsChar)):
            return lhsChar == rhsChar
        case (.and, .and), (.or, .or), (.if, .if), (.else, .else),
             (.endwhile, .endwhile), (.while, .while), (.assert, .assert),
             (.skip, .skip), (.not, .not), (.semicolon, .semicolon),
             (.leftParen, .leftParen),(.rightParen, .rightParen),
             (.plus, .plus), (.minus, .minus), (.lte, .lte), (.eq, .eq),
             (.assignEq, .assignEq), (.endif, .endif):
            return true
        default:
            return false
        }
    }
}

class Lexer {
    let input: String
    var index: String.Index

    init(input: String, filename: String) {
        self.input = input
        self.index = input.startIndex
    }

    func lex() -> [Token] {
        var toks = [Token]()
        while let tok = nextToken() {
            toks.append(tok)
        }
        index = input.startIndex
        return toks
    }

    var currentChar: Character? {
        return index < input.endIndex ? input[index] : nil
    }

    func advance() {
        if index < input.endIndex {
            _ = input.formIndex(after: &index)
        }
    }

    func peek() -> Character? {
        let nextIndex = input.index(after: index)
        guard nextIndex < input.endIndex else { return nil }
        return input[nextIndex]
    }

    func collectWhile(_ includeChar: (Character) -> Bool) -> String {
        var s = ""
        while let char = currentChar, includeChar(char) {
            s.append(char)
            advance()
        }
        return s
    }

    func nextToken() -> Token? {
        // Skip spaces
        while let char = currentChar, char.isSpace {
            advance()
        }

        // Check for EOF
        guard let char = currentChar else { return nil }

        if char.isNumeric {
            return .integer(Int(collectWhile { $0.isNumeric })!)
        } else if char.isAlphabetical {
            return Token(identifier: collectWhile { $0.isAlphanumeric })
        } else {
            switch char {
            case "+": advance(); return .plus
            case "-": advance(); return .minus
            case ";": advance(); return .semicolon
            case "(": advance(); return .leftParen
            case ")": advance(); return .rightParen
            case ":":
                if peek() == "=" {
                    advance(); advance()
                    return .assignEq
                }
            case "=":
                if peek() == "=" {
                    advance(); advance()
                    return .eq
                }
            case "<":
                if peek() == "=" {
                    advance(); advance()
                    return .lte
                }
            default:
                break
            }
            advance()
            return .unknown(char)
        }
    }
}
