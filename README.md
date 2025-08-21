# გითი

`giti` is a tiny Swift-based command-line tool that wraps common `git` commands into short, memorable verbs.  
It’s designed to speed up everyday Git workflows by reducing typing and boilerplate.

## Features

- Minimal syntax for common Git operations.
- Works inside any Git repository.
- Prints a compact view of recent commits and changes after each command.
- Small, single-binary tool — no dependencies beyond Swift.

## Installation

Build from source:
```bash
git clone https://github.com/P0ed/giti.git && cd giti
swift build -c release && cp .build/release/giti /usr/local/bin/
```
Now you can run giti from anywhere.


## Usage
```bash
giti [verb] [noun] [--force]
```

## Commands

| Verb   | Action                                                                           | Example                                |
| ------ | -------------------------------------------------------------------------------- | -------------------------------------- |
| `load` | Fetch all branches and prune deleted ones.                                       | `giti load`                            |
| `send` | Push current branch (or `noun`) to origin. Add `--force` to force push.          | `giti send main` / `giti send --force` |
| `name` | Rename current branch to `noun` (default: `main`).                               | `giti name feature-x`                  |
| `mkbr` | Create and switch to a new branch named `noun` (default: `main`).                | `giti mkbr hotfix`                     |
| `chbr` | Switch to branch `noun` (default: `main`).                                       | `giti chbr dev`                        |
| `set`  | Hard reset current branch to `noun` (default: `main`).                           | `giti set origin/main`                 |
| `mov`  | Rebase current branch onto `noun` (default: `main`). Add `--force` to pass `-f`. | `giti mov main`                        |
| `comb` | Merge `noun` into current branch with `--no-ff --no-edit`.                       | `giti comb develop`                    |
| `rec`  | Stage all changes and commit with message `noun` (default: `WIP`).               | `giti rec "Add login page"`            |
| `edit` | Amend last commit with staged changes and optional message `noun`.               | `giti edit "Fix typo"`                 |

If no command is given, giti simply prints the commit graph of the current repository.

## Output Example
```
+ 42 unrecorded changes
* 3f8c2c9 (HEAD -> main) Implement user login
* 9b1e3aa Add logout feature
* 82ac15d Merge branch 'feature/ui'
|\
| * 2d7a9cd Improve layout
|/
* f6dc2c9 Initial commit
-
-
```
