import Foundation
import ArgumentParser

@main
struct gitl: ParsableCommand {
	@Argument var verb: String?
	@Argument var noun: String?
	@Flag var force: Bool = false

	func run() throws {
		guard let repo = Repo.read() else { return print("Not a git repository") }

		switch verb {
		case "load": shell("git fetch --all -p")
		case "send": shell("git push origin \(noun ?? "HEAD")" + (force ? " -f" : ""))
		case "name": shell("git branch -m \(noun ?? "main")")
		case "mkbr": shell("git checkout -b \(noun ?? "main")")
		case "sel": shell("git checkout \(noun ?? "main")")
		case "mov": shell("git reset --hard \(noun ?? "main")")
		case "base": shell("git rebase \(noun ?? "main")")
		case "rec", "edit":
			let amend = verb == "edit" ? "--amend " : ""
			let msg = noun ?? "WIP"
			let taskMsg = repo.current.task.map { "[\($0)] \(msg)" } ?? msg
			shell("git add . && git commit \(amend)-m \"\(taskMsg)\"")
		default: break
		}

		if let repo = Repo.read() { print(repo) }
	}
}

struct Repo: Codable {
	var changes: String
	var branches: [Branch]
	var current: Branch
	var tree: [String]
}

struct Branch: Codable {
	var name: String
	var isCurrent: Bool

	init(_ branch: String) {
		name = branch.trimmingCharacters(in: CharacterSet(charactersIn: "* "))
		isCurrent = branch.hasPrefix("*")
	}
}

extension Repo: CustomStringConvertible {

	static func read() -> Repo? {
		let changes = shell("git diff")
		if changes.hasPrefix("fatal: not a git repository") { return nil }

		let branches = shell("git branch").split(separator: "\n").map { x in Branch(String(x)) }
		guard let current = branches.first(where: \.isCurrent) else { return nil }

		let tree = shell("git log --graph --oneline --decorate --all -36")
			.split(separator: "\n")
			.map(String.init)

		return Repo(changes: changes, branches: branches, current: current, tree: tree)
	}

	var description: String {
		let changesCount = changes.count
		let chs = changesCount > 0 ? "+ \(changesCount) unrecorded changes" : ""

		return ([chs] + tree).joined(separator: "\n")
	}
}

extension Branch {

	var task: String? {
		let s = name.split(separator: "-")
		return s.count < 2 ? nil : Int(s[1]).map { n in s[0] + "-" + n.description }
	}
}

extension String: @retroactive Error {}

@discardableResult
func shell(_ cmd: String) -> String {
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
