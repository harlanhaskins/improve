/// A Control Flow Graph is a DAG that represents the flow of information
/// through a program.
class CFGNode: Hashable {
    var successors = Set<CFGNode>()
    let assumptions: [BExp]
    let node: Node<Stmt>

    init(node: Node<Stmt>, assumptions: [BExp]) {
        self.assumptions = assumptions
    }

    func addSuccessor(_ successor: CFGNode) {
        successors.insert(successor)
    }

    /// Trivial equality: reference equality.
    static func ==(lhs: CFGNode, rhs: CFGNode) -> Bool {
        return lhs === rhs
    }

    /// Trivial hash function: pointer identity.
    var hashValue: Int {
        return ObjectIdentifier(self).hashValue
    }

    static func fromStmt(_ stmt: Node<Stmt>) -> CFGNode {
        switch stmt.kind {
        case let .assert(bexp):
            return CFGNode(node: stmt, assumptions: [bexp.kind])
        case let .assign(name, value):
            return CFGNode(node: stmt,
                           assumptions: [.eq(Node(kind: .identifier(name)),
                                             value)])
        case let .conditional(<#T##Node<BExp>#>, <#T##Node<Stmt>#>, <#T##Node<Stmt>#>)
        }
    }
}
