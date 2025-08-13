import Foundation

let shell: @Sendable (String) -> String = { cmd in
	let task = Process()
	let pipe = Pipe()

	task.executableURL = URL(fileURLWithPath: "/bin/zsh")
	task.standardInput = nil
	task.standardOutput = pipe
	task.standardError = pipe

	task.arguments = ["-c", cmd]

	do {
		try task.run()
		task.waitUntilExit()
		let data = pipe.fileHandleForReading.readDataToEndOfFile()
		let output = String(data: data, encoding: .utf8)!

		return output.trimmingCharacters(in: .newlines)
	} catch {
		return String(describing: error)
	}
}

let pshell = { @Sendable in print(shell($0)) }
