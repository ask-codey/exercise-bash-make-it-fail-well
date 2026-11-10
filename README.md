# Exercise: Make It Fail Well

Exercise code for the lesson **Exercise: Make It Fail Well** in Bash in Depth on [ask-codey.com](https://www.ask-codey.com).

`mover.sh` moves every photo from one folder into another, and it must never lose one. On a good day it works. On a bad day it says the wrong things in the wrong place, ends with the wrong exit code, leaves half-copied files behind, and has a bug that replaces a photo that was already there. Your job is to make it fail well, then write two tests of your own. A check script runs it for real, job by job, and tells you what's done.

## Before you start

You need a terminal (the Terminal app on a Mac, Ubuntu on Linux or in WSL on Windows) and **bats**, the tool that runs the check. If `bats --version` doesn't print a version yet, install it:

```bash
sudo apt install bats       # Ubuntu, and Ubuntu in WSL
brew install bats-core      # a Mac, with Homebrew
```

## What's here

- `mover.sh`: the mover, with eleven jobs, each a comment saying what to do and exactly what to print. For you to finish.
- `my-tests.bats`: one test for `mover.sh`, and room for the two you'll write (job 11).
- `inbox/` and `photos/`: practice photos (one-line text files) to try it on. `inbox/IMG_0412.jpg` is a beach; `photos/IMG_0412.jpg` is a birthday cake that must survive.
- `check.bats`: the check. You don't need to change it.

**A warning about the starter:** as it is, `mover.sh` can lose the practice photos, for example when you give it a TO folder that doesn't exist. That's exactly what you're fixing. If it happens, download the exercise again to get them back.

## Run it

Open a terminal in this folder (the one with `mover.sh` in it), let the script run, and open it:

```bash
chmod +x mover.sh
nano mover.sh
```

Write your code under each job's comment, save with Ctrl+O and Enter, and quit with Ctrl+X. Then try it:

```bash
./mover.sh
./mover.sh --help
./mover.sh inbx photos
./mover.sh inbox photos
```

The eleven jobs:

1. **Strict mode**: `set -euo pipefail`.
2. **A `die` function**: prints `mover: ` and its message on standard error, then stops with exit code 1.
3. **`--help`**: the usage line on standard output, exit code 0.
4. **Run wrong** (anything but two folders): the usage line on standard error, exit code 2.
5. **Missing folders**: `there's no folder called 'NAME'. Check the name with ls.` for the FROM folder, and `there's no folder called 'NAME'. Make it with mkdir, or check the name.` for the TO folder, both with `die`.
6. **Clean up**: `tmp=""`, then a `trap` that removes `"$tmp"` when the script exits.
7. **The bug**: a photo already in the TO folder gets replaced. Find why with `bash -x`, and fix it.
8. **Skipped photos**: the warning on standard error, and counted.
9. **A failed copy**: `die` with `couldn't copy NAME. It's still in FROM.`
10. **The summary**: `Done: N moved, M skipped.` on standard output, then exit code 1 when anything was skipped.
11. **Your tests**: two more tests in `my-tests.bats`, as its comment describes.

## Check your work

From this folder:

```bash
bats check.bats
```

At first most checks fail: that is expected. Each job you finish turns its check into a ✓. A failing check's message says what it expected, what your script printed on each stream, and what to look at. The check runs your script in a throwaway folder of its own, so the practice photos here are never touched. To run only your own tests:

```bash
bats my-tests.bats
```

## The rules

- Keep the script in `mover.sh`, and keep the `usage` line as it is.
- Print each message exactly as its job gives it: the check compares them word for word.
- Problems go on standard error (`>&2`); what the script did goes on standard output.

## Tips

- `echo "..." >&2` prints on standard error. `[[ -d "$src" ]] || die "..."` reads "it's a folder, or else die".
- With strict mode on, `"$1"` stops the script when there are no arguments. Write `"${1:-}"` in the `--help` test.
- Strict mode also stops at `((moved++))` when `moved` is 0. Write `moved=$((moved + 1))`.
- Put the trap's command in single quotes: `trap 'rm -f "$tmp"' EXIT`.
- For job 7, run `bash -x ./mover.sh inbox photos` and read the line that starts `+ [[ -e`. Which path did it really check?
- `cp ... || die "..."` dies when the copy fails, and the trap removes the half-copied file.
- In `my-tests.bats`, copy the first test and change it: `printf 'cake\n' > photos/IMG_0412.jpg` before `run`, and `[[ "$(cat photos/IMG_0412.jpg)" == "cake" ]]` after it.
- If you have ShellCheck, run `shellcheck mover.sh` when you're done.

## Hand it in

When it works, push your solution to a public repo of your own on GitHub, then paste that repo's address into **Submit your exercise** on the lesson page at [ask-codey.com](https://www.ask-codey.com). That's what completes the lesson. The lesson page shows the Git commands, step by step.
