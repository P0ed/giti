import ArgumentParser
import Foundation

@main
struct gitl: ParsableCommand {
	@Argument
	var verb: String?
	@Argument
	var noun: String?

	func run() throws {
		var repo: Repo? = .read()
		if repo == nil { return print("Not a git repository") }
		repo?.apply(verb: verb, noun: noun)
		repo = .read()
		repo?.list()
	}
}

extension String: @retroactive Error {}

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

extension Repo {

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

	func apply(verb: String?, noun: String?) {
		switch verb {
		case "load": load()
		case "send": send(force: noun == "rewrite")
		case "rec", "edit": rec(msg: noun, amend: verb == "edit")
		case "name": name(noun)
		case "mkbr": mkbr(name: noun)
		case "sel": sel(name: noun)
		case "mov": mov(dst: noun)
		case "base": base(dst: noun)
		default: break
		}
	}

	func load() {
		_ = shell("git fetch --all -p")
	}

	func send(force: Bool) {
		_ = shell("git push origin HEAD" + (force ? " -f" : ""))
	}

	func list() {
		let changesCount = changes.count
		if changesCount > 0 { print("+ \(changesCount) unrecorded changes") }

		print(tree.joined(separator: "\n"))
	}

	func name(_ name: String?) {
		_ = shell("git branch -m \(name ?? "main")")
	}

	func mkbr(name: String?) {
		_ = shell("git checkout -b \(name ?? "main")")
	}

	func sel(name: String?) {
		_ = shell("git checkout \(name ?? "main")")
	}

	func mov(dst: String?) {
		_ = shell("git reset --hard \(dst ?? "main")")
	}

	func base(dst: String?) {
		_ = shell("git rebase \(dst ?? "main")")
	}

	func rec(msg: String?, amend: Bool = false) {
		let msg = msg ?? "WIP"
		let taskMsg = current.task.map { "[\($0)] \(msg)" } ?? msg
		_ = shell("git add . && git commit \(amend ? "--amend " : "")-m \"\(taskMsg)\"")
	}
}

extension Branch {
	var task: String? {
		let s = name.split(separator: "-")
		return s.count < 2 ? nil : Int(s[1]).map { n in s[0] + "-" + n.description }
	}
}
