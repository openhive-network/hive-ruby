#!/usr/bin/env bash
# Run the checks named after the suite and write test-results/<suite>/junit.xml.
#
#   .aidev/run-checks.sh <suite> <step>...
#
# Steps, one junit case each (unit also writes minitest's per-test junit as
# unit-junit.xml):
#
#   unit    the Rakefile's default `test` task (every test/**/*_test.rb with
#           -W1, libs lib and test), excluding by name the tests listed in
#           .aidev/network-tests.txt (they need api.openhive.network)
#   syntax  ruby -wc over every .rb file under lib/, test/ and the Rakefile
#   docs    bundle exec yard (what CI's only job, `pages`, runs), into a
#           scratch directory under test-results/
#
# Not run: rake test:testnet / test:threads / stream:* (a live node).
#
# Runs offline in the image of .aidev/runtime/Dockerfile, which holds every gem
# and the Gemfile.lock it resolved; a checkout without Gemfile.lock (the
# repository ignores it) gets that one.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
root="$PWD"
suite="${1:?usage: $0 <suite> <step>...}"; shift
out="$root/test-results/$suite"
rm -rf "$out"; mkdir -p "$out"
cases="$out/cases.tsv"; : > "$cases"
[ -f Gemfile.lock ] || cp /opt/hive-ruby/Gemfile.lock Gemfile.lock

status=0
step() {
    local name="$1"; shift
    local log="$out/$name.log" t0=$SECONDS rc=0
    echo "== $name" >&2
    ( cd "$root" && "$@" ) > "$log" 2>&1 < /dev/null || rc=$?
    if [ "$rc" -eq 0 ]; then
        printf 'case\t%s\tpass\t%s\t\n' "$name" "$((SECONDS - t0))" >> "$cases"
    else
        status=1; tail -40 "$log" >&2
        printf 'case\t%s\tfail\t%s\texit %s\t%s\n' "$name" "$((SECONDS - t0))" "$rc" "$log" >> "$cases"
    fi
    return "$rc"
}

unit() {
    local names exclude rc=0
    names="$(grep -v '^[[:space:]]*\(#\|$\)' .aidev/network-tests.txt | sed 's/[?!]/\\&/g' | paste -sd'|')"
    exclude="/^(${names})\$/"
    # What Rakefile's `test` task runs (libs lib+test, -W1, test/**/*_test.rb),
    # loaded directly: rake hands TESTOPTS to sh, which cannot carry the regex.
    bundle exec ruby -W1 -Ilib -Itest \
        -e 'Dir["test/**/*_test.rb"].sort.each { |f| require File.expand_path(f) }' \
        -- -v "--exclude=${exclude}" 2>&1 | tee "$out/unit-run.log" || rc=${PIPESTATUS[0]}
    python3 .aidev/minitest_junit.py "$out/unit-junit.xml" "$out/unit-run.log" >&2
    return "$rc"
}

syntax() {
    local f rc=0
    while IFS= read -r f; do
        ruby -wc "$f" > /dev/null || { echo "syntax: $f" >&2; rc=1; }
    done < <(find lib test Rakefile -name '*.rb' -o -name Rakefile | sort)
    return "$rc"
}

docs() {
    bundle exec yard doc --no-save --no-cache -o "$out/yard"
}

for s in "$@"; do
    case "$s" in
        unit) step unit unit ;;
        syntax) step syntax syntax ;;
        docs) step docs docs ;;
        *) printf 'case\t%s\tfail\t0\tunknown step\n' "$s" >> "$cases"; status=1 ;;
    esac
done
python3 .aidev/junit_cases.py "$out/junit.xml" "$suite" "$cases"
exit "$status"
