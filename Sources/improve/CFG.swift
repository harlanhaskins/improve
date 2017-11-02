/// A Control Flow Graph is a DAG that represents the flow of information
/// through a program.
class CFGNode: Hashable {
    struct Transition: Hashable {
        let node: CFGNode
        let assumption: BExp?

        /// Trivial hash function: pointer identity and assumption description.
        var hashValue: Int {
            return node.hashValue ^ assumption.debugDescription.hashValue
        }

        /// Trivial equality: reference equality + comparing assumption descriptions.
        static func ==(lhs: Transition, rhs: Transition) -> Bool {
            return lhs.node == rhs.node &&
                lhs.assumption.debugDescription == rhs.assumption.debugDescription
        }
    }
    var successors = Set<Transition>()
    let stmt: Stmt?

    static func entry() -> CFGNode {
        return CFGNode(stmt: nil)
    }

    static func program(_ stmt: Stmt) -> CFGNode {
        let entry = CFGNode.entry()
        entry.addSuccessor(stmt)
        return entry
    }

    /// Adds the provided statement as a successor of the receiving CFG node.
    /// Along the transition, keeps track of any assumptions inherent in the
    /// statement.
    @discardableResult
    func addSuccessor(_ stmt: Stmt) -> CFGNode {
        switch stmt {
        case let .assert(bexp):
            let passNode = CFGNode(stmt: stmt)
            let errorNode = CFGNode(stmt: nil)
            addSuccessor(passNode, assumption: bexp)
            addSuccessor(errorNode, assumption: .not(bexp))
            return passNode
        case let .assign(name, value):
            let assignNode = CFGNode(stmt: stmt)
            addSuccessor(assignNode,
                         assumption: .eq(.identifier(name), value))
            return assignNode
        case let .conditional(cond, conseq, alter):
            let conseqNode = CFGNode(stmt: conseq)
            let alterNode = CFGNode(stmt: alter)
            let mergeNode = CFGNode(stmt: nil)
            addSuccessor(conseqNode, assumption: cond)
            let conseqEndNode = conseqNode.addSuccessor(conseq)
            conseqEndNode.addSuccessor(mergeNode, assumption: nil)

            addSuccessor(alterNode, assumption: .not(cond))
            let alterEndNode = alterNode.addSuccessor(alter)
            alterEndNode.addSuccessor(mergeNode, assumption: nil)

            return mergeNode
        case let .loop(cond, body):
            let bodyNode = CFGNode(stmt: body)
            let exitNode = CFGNode(stmt: nil)

            // Move into the body assuming the condition
            addSuccessor(bodyNode, assumption: cond)

            // Move back from the body assuming the condition
            bodyNode.addSuccessor(self, assumption: cond)

            // Exit the loop body assuming the condition no longer holds
            addSuccessor(exitNode, assumption: .not(cond))

            // Return the exit node
            return exitNode
        case let .seq(stmt1, stmt2):
            return addSuccessor(stmt1)
                      .addSuccessor(stmt2)
        case .skip:
            return self
        }
    }

    init(stmt: Stmt?) {
        self.stmt = stmt
    }

    private func addSuccessor(_ successor: CFGNode, assumption: BExp?) {
        successors.insert(Transition(node: successor, assumption: assumption))
    }

    /// Trivial hash function: pointer identity and assumption description.
    var hashValue: Int {
        return ObjectIdentifier(self).hashValue
    }

    /// Trivial equality: reference equality + comparing assumption descriptions.
    static func ==(lhs: CFGNode, rhs: CFGNode) -> Bool {
        return lhs === rhs
    }
}
