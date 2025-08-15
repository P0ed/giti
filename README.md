# gitl

`gitl` is a tiny Swift-based command-line tool that wraps common `git` commands into short, memorable verbs.  
It’s designed to speed up everyday Git workflows by reducing typing and boilerplate.

## Features

- Minimal syntax for common Git operations.
- Works inside any Git repository.
- Prints a compact view of recent commits and changes after each command.
- Small, single-binary tool — no dependencies beyond Swift.

## Installation

Build from source:
```bash
git clone https://github.com/P0ed/gitl.git
cd gitl
swift build -c release
cp .build/release/gitl /usr/local/bin/
```
Now you can run gitl from anywhere.


## Usage
```bash
gitl [verb] [noun] [--force]
```

## Commands

| Verb   | Noun                                                                           | Example                                |
| ------ | -------------------------------------------------------------------------------- | -------------------------------------- |
| `load` | Fetch all branches and prune deleted ones.                                       | `gitl load`                            |
| `send` | Push current branch (or `noun`) to origin. Add `--force` to force push.          | `gitl send main` / `gitl send --force` |
| `name` | Rename current branch to `noun` (default: `main`).                               | `gitl name feature-x`                  |
| `mkbr` | Create and switch to a new branch named `noun` (default: `main`).                | `gitl mkbr hotfix`                     |
| `chbr` | Switch to branch `noun` (default: `main`).                                       | `gitl chbr dev`                        |
| `set`  | Hard reset current branch to `noun` (default: `main`).                           | `gitl set origin/main`                 |
| `mov`  | Rebase current branch onto `noun` (default: `main`). Add `--force` to pass `-f`. | `gitl mov main`                        |
| `comb` | Merge `noun` into current branch with `--no-ff --no-edit`.                       | `gitl comb develop`                    |
| `rec`  | Stage all changes and commit with message `noun` (default: `WIP`).               | `gitl rec "Add login page"`            |
| `edit` | Amend last commit with staged changes and message `noun` (default: `WIP`).       | `gitl edit "Fix typo"`                 |

If no command is given, gitl simply prints the commit graph of the current repository.

## Output Example
```
+ 42 unrecorded changes
* 3f8c2c9 (HEAD -> main) Implement user login
* 9b1e3aa Add logout feature
* 82ac15d Merge branch 'feature/ui'
|\
| * 2d7a9cd Improve layout
...
```

