import ArgumentParser
import Foundation

@main
struct gitl: ParsableCommand {
	@Argument
	var verb: String?
	@Argument
	var noun: String?

	var repo: Repo?

	mutating func run() throws {
		repo = Repo()
		if repo == nil { return print("Not a git repository") }

		switch verb {
		case "load": load()
		case "send": send(force: noun == "force" || noun == "f")
		case "rec", "edit": rec(msg: noun, amend: verb == "edit")
		case "name": name(noun)
		case "mkbr": mkbr(name: noun)
		case "sel": sel(name: noun)
		case "mov": mov(dst: noun)
		case "base": base(dst: noun)
		default: break
		}
		info()
	}

	mutating func info() {
		repo = Repo()
		changes()
		list()
	}

	mutating func load() {
		_ = shell("git fetch --all -p")
		info()
	}

	func send(force: Bool) {
		_ = shell("git push origin HEAD" + (force ? " -f" : ""))
	}

	func changes() {
		let changesCount = repo?.changes.count ?? 0
		if changesCount > 0 { print("* - unrecorded changes \(changesCount)") }
	}

	func list() {
		pshell("git log --graph --oneline --decorate --all -36")
	}

	func name(_ name: String?) {
		let name = name ?? "main"
		_ = shell("git branch -m \(name)")
	}

	func mkbr(name: String?) {
		let name = name ?? "main"
		_ = shell("git checkout -b \(name)")
	}

	func sel(name: String?) {
		let name = name ?? "main"
		_ = shell("git checkout \(name)")
	}

	func mov(dst: String?) {
		let dst = dst ?? "main"
		_ = shell("git reset --hard \(dst)")
	}

	func base(dst: String?) {
		let dst = dst ?? "main"
		_ = shell("git rebase \(dst)")
	}

	func rec(msg: String?, amend: Bool = false) {
		let msg = msg ?? "WIP"
		let taskMsg = repo?.current.task.map { "[\($0)] \(msg)" } ?? msg
		_ = shell("git add . && git commit \(amend ? "--amend " : "")-m \"\(taskMsg)\"")
	}
}

extension String: @retroactive Error {}

struct Repo: Codable {
	var changes: String
	var branches: [Branch]
	var current: Branch

	init?() {
		let changes = shell("git diff")
		if changes.hasPrefix("fatal: not a git repository") { return nil }

		let branches = shell("git branch").split(separator: "\n").map { x in Branch(String(x)) }
		guard let current = branches.first(where: \.isCurrent) else { return nil }

		self.changes = changes
		self.branches = branches
		self.current = current
	}
}

struct Branch: Codable {
	var name: String
	var isCurrent: Bool

	init(_ name: String) {
		self.name = name.trimmingCharacters(in: CharacterSet(charactersIn: "* "))
		isCurrent = name.hasPrefix("*")
	}
}

extension Branch {
	var task: String? {
		let s = name.split(separator: "-")

		return s.count < 2 ? nil : Int(s[1]).map { n in s[0] + "-" + n.description }
	}
}
