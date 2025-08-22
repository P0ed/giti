import Foundation

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
