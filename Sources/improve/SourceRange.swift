struct SourceLocation {
    var line: Int
    var column: Int
    var file: String
}

struct SourceRange {
    let start: SourceLocation
    var end: SourceLocation
}
