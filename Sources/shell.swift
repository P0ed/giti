import Darwin
import Foundation

var termsize: (rows: Int, cols: Int)? {
	var w = winsize()
	let r = ioctl(STDOUT_FILENO, TIOCGWINSZ, &w)
	return r != 0 || w.ws_col == 0 || w.ws_row == 0 ? nil : (Int(w.ws_col), Int(w.ws_row))
}


@discardableResult
func shell(_ cmd: String) throws -> String {
	let pipe = Pipe()
	let process = Process()
	process.executableURL = URL(fileURLWithPath: "/bin/zsh")
	process.arguments = ["-c", cmd]
	process.standardInput = nil
	process.standardOutput = pipe
	process.standardError = pipe

	try process.run()
	process.waitUntilExit()
	let data = pipe.fileHandleForReading.readDataToEndOfFile()
	let output = String(data: data, encoding: .utf8)!.trimmingCharacters(in: .newlines)

	if process.terminationStatus == 0 { return output } else { throw output }
}

@discardableResult
func git(_ cmds: String...) throws -> String {
	try shell(cmds.map { "git " + $0 }.joined(separator: " && "))
}
