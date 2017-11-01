let input = """
if (r == 5)
    skip
else
    while (5 <= 3)
        skip;
"""

func main() throws {
    let lexer = Lexer(input: input, filename: "<input>")
    let parser = Parser(tokens: lexer.lex())
    dump(try parser.parseStmt())
}

do {
    try main()
} catch {
    print("error: \(error)")
}
