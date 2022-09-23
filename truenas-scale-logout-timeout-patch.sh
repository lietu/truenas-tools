#!/usr/bin/env bash
#
# Changes the logout timeout for TrueNAS Scale, defaults to 8h
#
# Based on https://www.truenas.com/community/threads/how-often-are-you-auto-logged-out.93614/#post-698140
#

# The wanted timeout can be given as an argument in seconds
TIMEOUT="${1:-28800}"

# Find the relevant files
GENERATE_TOKEN=$(grep -rnl 'auth.generate_token",\[' /usr/share/truenas/webui | grep -v .map | grep -v .orig)

# Make backups of originals, or restore to original state before patching
for f in $GENERATE_TOKEN; do
  target="${f}.orig"
  if [[ ! -f "$target" ]]; then
    cp -a "$f" "$target"
  else
    cp -a "$target" "$f"
  fi
done

for f in $GENERATE_TOKEN; do
  sed -Ei 's@auth.generate_token",\[300@auth.generate_token",\['"${TIMEOUT}"'@g' "$f"
done

# List changes
for f in $GENERATE_TOKEN; do
	echo "Patched $f token generation to $TIMEOUT seconds"
done
