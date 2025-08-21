import Foundation
import ArgumentParser
import Darwin

@main
struct Giti: ParsableCommand {

	static let configuration = CommandConfiguration(
		subcommands: [
			Load.self, Send.self, Rec.self, Edit.self,
			Mov.self, Name.self, MKBR.self, CHBR.self,
			NOFF.self, FMT.self, List.self,
		],
		defaultSubcommand: List.self
	)

	struct Load: ParsableCommand {
		func run() throws {
			try git("fetch --all -p")
			try print(Repo())
		}
	}
	struct Send: ParsableCommand {
		@Flag(name: .shortAndLong) var force: Bool = false
		@Argument var node: String?

		func run() throws {
			try git("push origin \(node ?? "HEAD")" + (force ? " --force" : ""))
			try print(Repo())
		}
	}
	struct Rec: ParsableCommand {
		@Argument var message: String?
		@Flag(name: .shortAndLong) var force: Bool = false
		@Flag(name: .shortAndLong) var sending: Bool = false

		func run() throws {
			let repo = try Repo()
			let msg = try repo.decoratedMessage(message ?? repo.generateMessage())
			try git("add .", "commit -m \"\(msg)\"")

			if sending {
				try git("push origin HEAD" + (force ? " --force" : ""))
			}
			try print(Repo())
		}
	}
	struct Edit: ParsableCommand {
		@Argument var message: String?
		@Flag(name: .shortAndLong) var force: Bool = false
		@Flag(name: .shortAndLong) var sending: Bool = false

		func run() throws {
			let repo = try Repo()
			let msg = message.map(repo.decoratedMessage) ?? repo.last
			try git("add .", "commit --amend -m \"\(msg)\"")

			if sending {
				try git("push origin HEAD" + (force ? " --force" : ""))
			}
			try print(Repo())
		}
	}
	struct Mov: ParsableCommand {
		@Argument var node: String?
		@Flag(name: .shortAndLong) var force: Bool = false

		func run() throws {
			try git("rebase \(node ?? "origin/main")" + (force ? " --force" : ""))
			try print(Repo())
		}
	}
	struct Name: ParsableCommand {
		@Argument var node: String?

		func run() throws {
			try git("branch -m \(node ?? "main")")
			try print(Repo())
		}
	}
	struct CHBR: ParsableCommand {
		@Argument var node: String?

		func run() throws {
			try git("checkout \(node ?? "main")")
			try print(Repo())
		}
	}
	struct MKBR: ParsableCommand {
		@Argument var node: String?
		func run() throws {
			try git("checkout -b \(node ?? "main")")
			try print(Repo())
		}
	}
	struct NOFF: ParsableCommand {
		@Argument var node: String?

		func run() throws {
			try git("merge --no-ff --no-edit \(node ?? "main")")
			try print(Repo())
		}
	}
	struct FMT: ParsableCommand {
		@Argument var fmt: String?

		func run() throws {
			if let fmt {
				UserDefaults.standard.messageFormat = fmt
			} else {
				print(UserDefaults.standard.messageFormat)
			}
		}
	}
	struct List: ParsableCommand {
		func run() throws { try print(Repo()) }
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

extension UserDefaults {

	var messageFormat: String {
		get { string(forKey: "messageFormat") ?? "#MSG" }
		set { set(newValue.contains("#MSG") ? newValue : nil, forKey: "messageFormat") }
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

	func generateMessage() throws -> String {
		let changedFiles = try git("diff --name-only HEAD")
			.split(separator: "\n")
			.map { path in URL(fileURLWithPath: String(path)).lastPathComponent }
		return "Update \(changedFiles.joined(separator: ", "))"
	}
}

extension String: @retroactive Error {}

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

var termsize: (rows: Int, cols: Int)? {
	var w = winsize()
	let r = ioctl(STDOUT_FILENO, TIOCGWINSZ, &w)
	return r != 0 || w.ws_col == 0 || w.ws_row == 0 ? nil : (Int(w.ws_col), Int(w.ws_row))
}

extension Repo {

	private var task: String? {
		current.flatMap { branch in
			let s = branch.name.split(separator: "-")
			var isUppercase: Bool { s.count < 2 ? false : !s[0].contains { !$0.isUppercase } }
			var isNumber: Bool { s.count < 2 ? false : !s[1].contains { !$0.isNumber } }
			return isUppercase && isNumber ? "\(s[0])-\(s[1])" : nil
		}
	}

	func decoratedMessage(_ msg: String) -> String {
		task.map { task in
			UserDefaults.standard.messageFormat
				.replacingOccurrences(of: "#TASK", with: task)
				.replacingOccurrences(of: "#MSG", with: msg)
		} ?? msg
	}
}
