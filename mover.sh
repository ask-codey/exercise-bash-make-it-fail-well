#!/usr/bin/env bash
# mover.sh: moves every file from one folder into another, and must never lose one.
#
#   ./mover.sh FROM-FOLDER TO-FOLDER    move every file across, never replacing one
#   ./mover.sh --help                   show how to use it
#
# It works on a good day. Your jobs, the numbered comments, make it fail well.
# The messages are given exactly, because the check compares them word for word.
# NAME stands for a file's or a folder's name.

# 1. Turn on strict mode.


usage="Usage: mover.sh FROM-FOLDER TO-FOLDER"

# 2. Write a die function: it prints "mover: " and its message on standard
#    error, then stops the script with exit code 1.


# 3. --help: print the usage line on standard output, and stop with exit code 0.
# 4. Anything but two arguments: print the usage line on standard error, and
#    stop with exit code 2.


src="$1"
dest="$2"

# 5. No FROM folder by that name: die with
#      there's no folder called 'NAME'. Check the name with ls.
#    No TO folder by that name: die with
#      there's no folder called 'NAME'. Make it with mkdir, or check the name.


# 6. Clean up after yourself: set tmp to "" here, and set a trap that removes
#    "$tmp" when the script exits, however it ends.


moved=0
skipped=0
for file in "$src"/*; do
  [[ -e "$file" ]] || continue
  name=$(basename "$file")
  # 7. A bug: this check never finds the photo that's already there, so a
  #    photo can be replaced and lost. Find it with bash -x, and fix it.
  if [[ -e "$dest/$file" ]]; then
    # 8. This warning belongs on standard error, and it should count the
    #    photo as skipped.
    echo "mover: skipped $name: $dest already has one."
    continue
  fi
  tmp=$(mktemp "$dest/.moving.XXXXXX")
  # 9. When the copy fails, die with
  #      couldn't copy NAME. It's still in FROM.
  #    (FROM is the folder's name, such as inbox.)
  cp -p "$file" "$tmp"
  mv "$tmp" "$dest/$name"
  rm "$file"
  echo "Moved $name."
  ((moved++))
done

# 10. Print "Done: N moved, M skipped." on standard output, with the two
#     counts. Then, when anything was skipped, stop with exit code 1.

