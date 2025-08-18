import Foundation
import ArgumentParser

@main
struct giti: ParsableCommand {
	@Argument var verb: String?
	@Argument var noun: String?
	@Flag var force: Bool = false

	mutating func run() throws {
		let _ = try Repo.status()

		switch verb {
		case "load": try git("fetch --all -p")
		case "send": try git("push origin \(noun ?? "HEAD")" + (force ? " -f" : ""))
		case "name": try git("branch -m \(noun ?? "main")")
		case "mkbr": try git("checkout -b \(noun ?? "main")")
		case "chbr": try git("checkout \(noun ?? "main")")
		case "set": try git("reset --hard \(noun ?? "main")")
		case "mov": try git("rebase \(noun ?? "main")" + (force ? " -f" : ""))
		case "comb": try git("merge --no-ff --no-edit \(noun ?? "main")")
		case "rec", "edit": try rec(edit: verb == "edit", message: noun)
		case let .some(verb): throw "Unknown verb: \(verb)"
		case .none: break
		}

		try print(Repo())
	}

	func rec(edit: Bool, message: String?) throws {
		let repo = try Repo()
		let msg = try message ?? (edit ? git("log -1 --pretty=%B") : "WIP")
		let decorated = repo.current?.task.map { task in "[\(task)] \(msg)" } ?? msg
		try git("add .", "commit \(edit ? "--amend " : "")-m \"\(decorated)\"")
	}
}

struct Repo {
	var changes: String
	var branches: [Branch]
	var tree: [String]
}

struct Branch {
	var name: String
	var isCurrent: Bool

	init(_ branch: String) {
		name = branch.trimmingCharacters(in: CharacterSet(charactersIn: "* "))
		isCurrent = branch.hasPrefix("*")
	}

	var task: String? {
		let s = name.split(separator: "-")
		return s.count < 2 ? nil : Int(s[1]).map { i in "\(s[0])-\(i)" }
	}
}

extension Repo: CustomStringConvertible {

	var current: Branch? { branches.first(where: \.isCurrent) }
	static func status() throws -> String { try git("status") }

	init() throws {
		self = try Repo(
			changes: git("diff"),
			branches: git("branch").split(separator: "\n").map { x in Branch(String(x)) },
			tree: git("log --graph --oneline --decorate --all -36")
				.split(separator: "\n")
				.prefix(36)
				.map(String.init)
		)
	}

	var description: String {
		let changesCount = changes.count
		let chs = changesCount > 0 ? "+ \(changesCount) unrecorded changes\n" : ""

		return chs + tree.joined(separator: "\n")
	}
}

extension String: @retroactive Error {}

@discardableResult
func shell(_ cmd: String) throws -> String {
	let process = Process()
	let pipe = Pipe()

	process.executableURL = URL(fileURLWithPath: "/bin/zsh")
	process.standardInput = nil
	process.standardOutput = pipe
	process.standardError = pipe

	process.arguments = ["-c", cmd]

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
