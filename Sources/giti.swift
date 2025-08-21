import Foundation
import ArgumentParser
import Darwin

@main
struct giti: ParsableCommand {
	@Argument var verb: String?
	@Argument var noun: String?
	@Flag(name: .shortAndLong) var force: Bool = false
	@Flag(name: .shortAndLong) var sending: Bool = false

	func run() throws {
		let repo = try Repo()

		switch verb {
		case "load": try git("fetch --all -p")
		case "send": try repo.send(noun: noun, force: force)
		case "rec", "edit": try repo.rec(verb: verb, noun: noun, force: force, sending: sending)
		case "mov": try git("rebase \(noun ?? "origin/main")" + (force ? " --force" : ""))
		case "name": try git("branch -m \(noun ?? "main")")
		case "mkbr": try git("checkout -b \(noun ?? "main")")
		case "chbr": try git("checkout \(noun ?? "main")")
		case "set": try git("reset --hard \(noun ?? "main")")
		case "comb": try git("merge --no-ff --no-edit \(noun ?? "main")")
		case let .some(verb): throw "Unknown verb: \(verb)"
		case .none: break
		}

		try print(Repo())
	}
}

struct Repo {
	var status: String
	var changes: String
	var branches: [Branch]
	var tree: [String]
	var last: String
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

	var description: String {
		let lines = (termsize?.cols ?? 24) - 1
		let changesCount = changes.count
		let chs = changesCount > 0 ? ["+ \(changesCount) unrecorded changes"] : []
		let all = chs + tree + (0..<max(0, lines - tree.count - chs.count)).map { _ in "-" }
		return all.prefix(lines).joined(separator: "\n")
	}
}

extension Repo {

	var current: Branch? { branches.first(where: \.isCurrent) }

	init() throws {
		self = try Repo(
			status: git("status"),
			changes: git("diff"),
			branches: git("branch").split(separator: "\n").map { x in Branch(String(x)) },
			tree: git("log --graph --oneline --decorate --all -64")
				.split(separator: "\n")
				.map(String.init),
			last: git("log -1 --pretty=%B")
		)
	}

	func send(noun: String? = nil, force: Bool) throws {
		try git("push origin \(noun ?? "HEAD")" + (force ? " --force" : ""))
	}

	func rec(verb: String?, noun: String?, force: Bool, sending: Bool) throws {
		let edit = verb == "edit"
		let msg = try decorator(noun ?? (edit ? last : generateCommitMessage()))
		try git("add .", "commit \(edit ? "--amend " : "")-m \"\(msg)\"")

		if sending { try send(force: force) }
	}

	func generateCommitMessage() throws -> String {
		let changedFiles = try git("diff --name-only HEAD")
			.split(separator: "\n")
			.map { path in URL(fileURLWithPath: String(path)).lastPathComponent }
		return "Update \(changedFiles.joined(separator: ", "))"
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

var termsize: (rows: Int, cols: Int)? {
	var w = winsize()
	let r = ioctl(STDOUT_FILENO, TIOCGWINSZ, &w)
	return r != 0 ? nil : (Int(w.ws_col), Int(w.ws_row))
}

func id<A>(_ x: A) -> A { x }

extension Repo {

	private var task: String? {
		current.flatMap { branch in
			let s = branch.name.split(separator: "-")
			var isUppercase: Bool { s.count < 2 ? false : !s[0].contains { !$0.isUppercase } }
			var isNumber: Bool { s.count < 2 ? false : !s[1].contains { !$0.isNumber } }
			return isUppercase && isNumber ? "\(s[0])-\(s[1])" : nil
		}
	}

	var decorator: @Sendable (String) -> String {
		ProcessInfo.processInfo.environment["GITI_DECORATOR"]
			.flatMap { fmt in
				fmt.split(separator: "%s", omittingEmptySubsequences: false).count == 3 ? fmt : nil
			}
			.flatMap { fmt in
				task.map { task in
					{ msg in String(format: fmt, task, msg) }
				}
			}
			?? id
	}
}
