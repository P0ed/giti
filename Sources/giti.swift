import Foundation
import ArgumentParser
import Darwin

@main
struct Giti: ParsableCommand {

	static let configuration = CommandConfiguration(
		subcommands: [
			Load.self, Send.self, Rec.self, Edit.self,
			Mov.self, Name.self, MKBR.self, CHBR.self,
			NOFF.self, List.self, FMT.self,
		],
		defaultSubcommand: List.self
	)

	struct Load: RepoCommand {
		static let configuration = CommandConfiguration(
			abstract: "Fetch all remote branches and prune deleted references",
			usage: "giti load"
		)
		
		func run(repo: Repo) throws {
			try git("fetch --all -p")
		}
	}
	struct Send: RepoCommand {
		@Flag(name: .shortAndLong) var force: Bool = false
		@Argument var node: String?

		static let configuration = CommandConfiguration(
			abstract: "Push commits to the remote repository",
			usage: "giti send [<node>] [--force]"
		)

		func run(repo: Repo) throws {
			try git("push origin \(node ?? "HEAD")" + (force ? " --force" : ""))
		}
	}
	struct Rec: RepoCommand {
		@Argument var message: String?
		@Flag(name: .shortAndLong) var force: Bool = false
		@Flag(name: .shortAndLong) var sending: Bool = false

		static let configuration = CommandConfiguration(
			abstract: "Record changes by staging and committing them",
			usage: "giti rec [<message>] [--force] [--sending]"
		)

		func run(repo: Repo) throws {
			let msg = try repo.decoratedMessage(message ?? repo.generateMessage())
			try git("add .", "commit -m \"\(msg)\"")

			if sending {
				try git("push origin HEAD" + (force ? " --force" : ""))
			}
		}
	}
	struct Edit: RepoCommand {
		@Argument var message: String?
		@Flag(name: .shortAndLong) var force: Bool = false
		@Flag(name: .shortAndLong) var sending: Bool = false
		
		static let configuration = CommandConfiguration(
			abstract: "Edit the last commit by amending it with current changes",
			usage: "giti edit [<message>] [--force] [--sending]"
		)

		func run(repo: Repo) throws {
			let msg = message.map(repo.decoratedMessage) ?? repo.last
			try git("add .", "commit --amend -m \"\(msg)\"")

			if sending {
				try git("push origin HEAD" + (force ? " --force" : ""))
			}
		}
	}
	struct Mov: RepoCommand {
		@Argument var node: String?
		@Flag(name: .shortAndLong) var force: Bool = false

		static let configuration = CommandConfiguration(
			abstract: "Move current branch by rebasing onto another branch",
			usage: "giti mov [<node>] [--force]"
		)

		func run(repo: Repo) throws {
			try git("rebase \(node ?? "origin/main")" + (force ? " --force" : ""))
		}
	}
	struct Name: RepoCommand {
		@Argument var node: String?

		static let configuration = CommandConfiguration(
			abstract: "Rename the current branch",
			usage: "giti name [<node>]"
		)

		func run(repo: Repo) throws {
			try git("branch -m \(node ?? "main")")
		}
	}
	struct CHBR: RepoCommand {
		@Argument var node: String?

		static let configuration = CommandConfiguration(
			abstract: "Check out an existing branch",
			usage: "giti chbr [<node>]"
		)

		func run(repo: Repo) throws {
			try git("checkout \(node ?? "main")")
		}
	}
	struct MKBR: RepoCommand {
		@Argument var node: String?

		static let configuration = CommandConfiguration(
			abstract: "Create and check out a new branch",
			usage: "giti mkbr [<node>]"
		)
		
		func run(repo: Repo) throws {
			try git("checkout -b \(node ?? "main")")
		}
	}
	struct NOFF: RepoCommand {
		@Argument var node: String?

		static let configuration = CommandConfiguration(
			abstract: "Merge a branch with no fast-forward",
			usage: "giti noff [<node>]"
		)
		
		func run(repo: Repo) throws {
			try git("merge --no-ff --no-edit \(node ?? "main")")
		}
	}
	struct List: RepoCommand {
		static let configuration = CommandConfiguration(
			abstract: "Display repository status and commit tree (default command)",
			usage: "giti [list]"
		)
	}
	struct FMT: ParsableCommand {
		@Argument var fmt: String?

		static let configuration = CommandConfiguration(
			abstract: "Get or set the commit message format template",
			usage: "giti fmt [<format>]"
		)

		func run() throws {
			if let fmt {
				UserDefaults.standard.messageFormat = fmt
			} else {
				print(UserDefaults.standard.messageFormat)
			}
		}
	}
}

protocol RepoCommand: ParsableCommand {
	func run(repo: Repo) throws
}

extension RepoCommand {

	func run(repo: Repo) throws {}

	func run() throws {
		try run(repo: Repo())
		try print(Repo())
	}
}

extension Repo {

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
