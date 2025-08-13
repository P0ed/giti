import Foundation
import ArgumentParser

@main
struct gitl: ParsableCommand {
	@Argument var verb: String?
	@Argument var noun: String?
	@Flag var force: Bool = false

	mutating func run() throws {
		if Repo.status == nil { throw "Not a git repository" }

		switch verb {
		case "load": try git("fetch --all -p")
		case "send": try git("push origin \(noun ?? "HEAD")" + (force ? " -f" : ""))
		case "name": try git("branch -m \(noun ?? "main")")
		case "mkbr": try git("checkout -b \(noun ?? "main")")
		case "chbr": try git("checkout \(noun ?? "main")")
		case "set": try git("reset --hard \(noun ?? "main")")
		case "mov": try git("rebase \(noun ?? "main")" + (force ? " -f" : ""))
		case "comb": try git("merge --no-ff --no-edit \(noun ?? "main")")
		case "rec", "edit": try git("add .", "commit \(verb == "edit" ? "--amend " : "")-m \"\(noun ?? "WIP")\"")
		case let .some(verb): throw "Unknown verb: \(verb)"
		case .none: break
		}

		try print(Repo())
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
}

extension Repo: CustomStringConvertible {

	var current: Branch? { branches.first(where: \.isCurrent) }
	static var status: String? { try? git("status") }

	init() throws {
		self = try Repo(
			changes: git("diff"),
			branches: git("branch").split(separator: "\n").map { x in Branch(String(x)) },
			tree: git("log --graph --oneline --decorate --all -36")
				.split(separator: "\n")
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
