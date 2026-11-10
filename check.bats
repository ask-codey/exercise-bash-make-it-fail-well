#!/usr/bin/env bats
# Checks your mover.sh by running it for real, job by job, and runs your own
# tests in my-tests.bats. Every check runs the mover in a throwaway folder of its
# own, with made-up photos, so nothing in this exercise folder is changed.
# Run it from this folder with:  bats check.bats
# You don't need to change this file.

# run --separate-stderr, used below, needs bats 1.5.0 or newer.
bats_require_minimum_version 1.5.0

setup() {
  script="$BATS_TEST_DIRNAME/mover.sh"
  dir="$BATS_TEST_TMPDIR/practice"
  mkdir -p "$dir/inbox" "$dir/photos"
  cd "$dir"
  usage="Usage: mover.sh FROM-FOLDER TO-FOLDER"
}

teardown() {
  # Job 9's check takes the read permission away from a photo; give it back,
  # so the throwaway folder can be cleaned up.
  chmod -R u+rw "$dir" 2>/dev/null || true
}

# Runs your mover with bash, so it doesn't need chmod +x. Its standard output
# lands in $output and its standard error in $stderr.
mover() {
  run --separate-stderr bash "$script" "$@"
}

# Three made-up photos waiting in inbox/, one with a space in its name.
three_photos() {
  printf 'beach\n' > inbox/IMG_0412.jpg
  printf 'sunset\n' > inbox/IMG_0413.jpg
  printf 'waves\n' > "inbox/beach day.jpg"
}

# Fails with a message when the exit code isn't the one the job asks for.
expect_status() {
  if [[ "$status" -ne "$1" ]]; then
    echo "$2 (it gave exit code $status)."
    return 1
  fi
}

# Fails when the script printed something on the wrong stream.
expect_streams() {
  if [[ "$output" != "$1" || "$stderr" != "$2" ]]; then
    echo "$3"
    echo "Expected on standard output: ${1:-(nothing)}"
    echo "It printed there:            ${output:-(nothing)}"
    echo "Expected on standard error:  ${2:-(nothing)}"
    echo "It printed there:            ${stderr:-(nothing)}"
    return 1
  fi
}

# Any half-copied .moving file left in photos/.
leftovers() {
  find photos -name '.moving.*'
}

@test "the script is here and bash can read it" {
  if [[ ! -f "$script" ]]; then
    echo "mover.sh is missing. Download the exercise again to get it back."
    return 1
  fi
  errors="$(bash -n "$script" 2>&1)" || {
    echo "bash found a mistake in mover.sh before running it:"
    echo "$errors" | head -n 1
    echo "Look at the line it names. Common causes: a missing fi or }, or no space inside [[ ]]."
    return 1
  }
}

@test "1) strict mode is on" {
  if ! grep -Eq '^[[:space:]]*set -euo pipefail[[:space:]]*$' "$script"; then
    echo "Put the line set -euo pipefail near the top of mover.sh, under job 1's comment."
    return 1
  fi
}

@test "3) --help prints the usage line on standard output" {
  mover --help
  expect_streams "$usage" "" "--help should print only the usage line, on standard output: a plain echo \"\$usage\"." || return 1
  expect_status 0 "--help should stop with exit 0: asking for help isn't a mistake"
}

@test "4) run with nothing, it prints the usage line on standard error" {
  mover
  expect_streams "" "$usage" "Run with nothing, the usage line belongs on standard error: echo \"\$usage\" >&2. If it says \"unbound variable\", write \"\${1:-}\" in the --help test." || return 1
  expect_status 2 "Run wrong, the script should stop with exit 2, the code for \"used the wrong way\""
}

@test "4) run with one folder, it prints the usage line too" {
  mover inbox
  expect_streams "" "$usage" "With one folder instead of two, the script should print the usage line on standard error. Check \$# with -ne 2, before src=\"\$1\"." || return 1
  expect_status 2 "Run wrong, the script should stop with exit 2"
}

@test "2) 5) a missing FROM folder: die says so" {
  mover inbx photos
  expect_streams "" "mover: there's no folder called 'inbx'. Check the name with ls." "For a FROM folder that isn't there, die with the message from job 5. die prints \"mover: \" and the message with >&2." || return 1
  expect_status 1 "die should stop the script with exit 1"
}

@test "2) 5) a missing TO folder: die says so" {
  three_photos
  mover inbox pictures
  expect_streams "" "mover: there's no folder called 'pictures'. Make it with mkdir, or check the name." "For a TO folder that isn't there, die with job 5's second message." || return 1
  expect_status 1 "die should stop the script with exit 1" || return 1
  if [[ ! -f inbox/IMG_0412.jpg ]]; then
    echo "The photos should still be in inbox/: check both folders before the loop."
    return 1
  fi
}

@test "7) 8) never replaces a photo that's already there" {
  three_photos
  printf 'cake\n' > photos/IMG_0412.jpg
  mover inbox photos
  if [[ "$(cat photos/IMG_0412.jpg)" != "cake" ]]; then
    echo "photos/IMG_0412.jpg was replaced, and the cake photo is lost. That's job 7's bug: run bash -x ./mover.sh inbox photos and read the [[ -e ... ]] lines."
    return 1
  fi
  if [[ ! -f inbox/IMG_0412.jpg ]]; then
    echo "The new IMG_0412.jpg should stay in inbox/ when photos/ already has one."
    return 1
  fi
  if [[ "$output" == *"mover: skipped"* ]]; then
    echo "The warning was printed on standard output. Add >&2 to its echo (job 8)."
    return 1
  fi
  if [[ "$stderr" != *"mover: skipped IMG_0412.jpg: photos already has one."* ]]; then
    echo "The warning \"mover: skipped IMG_0412.jpg: photos already has one.\" belongs on standard error. It printed there: ${stderr:-(nothing)}"
    return 1
  fi
}

@test "8) 10) moves every photo and says how many" {
  three_photos
  mover inbox photos
  if [[ ! -f photos/IMG_0412.jpg || ! -f photos/IMG_0413.jpg || ! -f "photos/beach day.jpg" ]]; then
    echo "All three photos should be in photos/. It printed: $output $stderr"
    if [[ "$status" -ne 0 && "$output" == "Moved "*"." && "$output" != *$'\n'* ]]; then
      echo "It stopped after the first photo. With strict mode on, ((moved++)) stops the script when moved is 0. Write moved=\$((moved + 1))."
    fi
    return 1
  fi
  if [[ "$output" != *"Done: 3 moved, 0 skipped." ]]; then
    echo "The last line on standard output should be \"Done: 3 moved, 0 skipped.\" (job 10). It printed: $output"
    return 1
  fi
  expect_status 0 "When every photo moved, the script should end with exit 0"
}

@test "8) 10) a skipped photo is counted, and the exit code says so" {
  three_photos
  printf 'cake\n' > photos/IMG_0412.jpg
  mover inbox photos
  if [[ "$output" != *"Done: 2 moved, 1 skipped." ]]; then
    echo "With one photo skipped, the last line should be \"Done: 2 moved, 1 skipped.\" Count it with skipped=\$((skipped + 1)) beside the warning. It printed: $output"
    return 1
  fi
  expect_status 1 "When anything was skipped, the script should stop with exit 1, so whoever runs it knows to look"
}

@test "6) 9) a failed copy: it says so and leaves no half-copied file" {
  if [[ "$(id -u)" -eq 0 ]]; then
    skip "running as root, which can read anything, so a copy can't be made to fail"
  fi
  printf 'sunset\n' > inbox/IMG_0413.jpg
  chmod a-r inbox/IMG_0413.jpg
  mover inbox photos
  if [[ "$stderr" != *"mover: couldn't copy IMG_0413.jpg. It's still in inbox."* ]]; then
    echo "When cp fails (here, the photo can't be read), die with job 9's message: put || die \"...\" after the cp line. It printed on standard error: ${stderr:-(nothing)}"
    return 1
  fi
  expect_status 1 "A failed copy should stop the script with exit 1" || return 1
  if [[ ! -e inbox/IMG_0413.jpg ]]; then
    echo "The photo that couldn't be copied should still be in inbox/."
    return 1
  fi
  if [[ -n "$(leftovers)" ]]; then
    echo "A half-copied file was left behind: $(leftovers). Job 6: tmp=\"\" and trap 'rm -f \"\$tmp\"' EXIT, above the loop."
    return 1
  fi
}

@test "11) your own tests: at least three, and they pass" {
  tests="$BATS_TEST_DIRNAME/my-tests.bats"
  count=$(grep -c '^@test' "$tests" || true)
  if [[ "$count" -lt 3 ]]; then
    echo "my-tests.bats has $count tests. Write the two that job 11 describes, each starting with @test."
    return 1
  fi
  run bats "$tests"
  if [[ "$status" -ne 0 ]]; then
    echo "Your tests in my-tests.bats don't all pass yet. Run bats my-tests.bats to see which, and why:"
    echo "$output"
    return 1
  fi
}
