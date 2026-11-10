#!/usr/bin/env bats
# my-tests.bats: your own tests for mover.sh. Run them with:  bats my-tests.bats
# Each test runs mover.sh in a throwaway folder that setup makes, so your
# practice files are never touched.

setup() {
  mover="$BATS_TEST_DIRNAME/mover.sh"
  cd "$BATS_TEST_TMPDIR"
  mkdir inbox photos
  printf 'beach\n' > inbox/IMG_0412.jpg
}

@test "moves a photo into the photos folder" {
  run bash "$mover" inbox photos
  [[ "$status" -eq 0 ]]
  [[ -f photos/IMG_0412.jpg ]]
  [[ ! -e inbox/IMG_0412.jpg ]]
}

# 11. Write two more tests below, each with @test, a name in quotes, run, and
#     checks with [[ ]]:
#     - "never replaces a photo that's already there": put a photos/IMG_0412.jpg
#       that says cake there first, run the mover, and check that its exit code
#       is 1 and that photos/IMG_0412.jpg still says cake.
#     - "with no folders, it shows how to use it": run the mover with nothing
#       after its name, and check that its exit code is 2.
