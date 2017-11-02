import Foundation

func run(_ exeName: String, _ args: String...) -> Data {
    let stdoutPipe = Pipe()
    var stdoutData = Data()
    stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
        stdoutData += handle.availableData
    }
    let process = Process()
    process.launchPath = "/usr/bin/env"
    process.arguments = [exeName] + args
    process.standardOutput = stdoutPipe
    process.launch()
    process.waitUntilExit()
    return stdoutData
}
