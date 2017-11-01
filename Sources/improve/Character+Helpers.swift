#if os(macOS)
import Darwin
#elseif os(Linux)
import Glibc
#endif

extension Character {
    var scalarValue: Int32? {
        return unicodeScalars.count == 1 ? Int32(unicodeScalars.first!.value) : nil
    }

    var isSpace: Bool {
        guard let value = scalarValue else { return false }
        return isspace(value) != 0
    }

    var isAlphabetical: Bool {
        guard let value = scalarValue else { return false }
        return isalpha(value) != 0
    }

    var isAlphanumeric: Bool {
        guard let value = scalarValue else { return false }
        return isalnum(value) != 0
    }

    var isNumeric: Bool {
        guard let value = scalarValue else { return false }
        return isnumber(value) != 0
    }
}
