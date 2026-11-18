#!/usr/bin/env bash
# Usage: ./reason.sh OUT.ttl FILE.ttl...
#
# Runs EYE with every rule in rules/ over the files given, and writes the
# files plus everything inferred from them to OUT.ttl. If the rules
# conclude `false` (a contradiction), prints the triples that contradict
# each other, writes nothing, and exits 2.
set -uo pipefail
out=$1; shift
mkdir -p "$(dirname "$out")"
rm -f "$out"
eye --quiet --nope rules/*.n3 "$@" --pass-only-new > "$out.n3" 2> "$out.log"
status=$?
if [ $status -eq 2 ]; then
  echo "** CONTRADICTION: these can't all be true **"
  sed -n '/^{/,/=> false/p' "$out.log"
  exit 2
elif [ $status -ne 0 ]; then
  cat "$out.log" >&2
  exit $status
fi
riot --quiet --formatted=ttl "$@" "$out.n3" > "$out"
