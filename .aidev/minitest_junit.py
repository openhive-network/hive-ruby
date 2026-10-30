#!/usr/bin/env python3
"""Turn minitest's verbose output into a junit report (stdlib only).

    minitest_junit.py JUNIT LOG

LOG is the output of a `-v` minitest run: one `Class#test_name = 0.01 s = R`
line per test (R is . pass, F failure, E error, S skip), then numbered
Failure:/Error:/Skipped: blocks, whose text becomes the case's body.
"""
import re
import sys
from xml.sax.saxutils import escape, quoteattr

junit, log = sys.argv[1:3]
text = open(log, encoding="utf-8", errors="replace").read()
text = re.sub(r"\x1b\[[0-9;]*[A-Za-z]", "", text)
# A test that prints to stdout splits its result line; allow output in between.
results = re.findall(r"^(\S+)#(\S+) = (?:[^\n]*\n){0,20}?[^\n]*?\b([0-9]+\.[0-9]+) s = ([.FES])$", text, re.M)
details = {}
for block in re.split(r"\n(?=\s*\d+\) (?:Failure|Error|Skipped):)", text):
    m = re.match(r"\s*\d+\) (?:Failure|Error|Skipped):\n(\S+#[^\s:\[]+)", block)
    if m:
        details[m.group(1)] = block.strip()[:8000]
kinds = {".": None, "F": "failure", "E": "error", "S": "skipped"}
body = []
for cls, name, secs, r in results:
    head = "<testcase classname=%s name=%s time=\"%s\">" % (quoteattr(cls), quoteattr(name), secs)
    kind = kinds[r]
    detail = details.get(cls + "#" + name, "")
    if kind == "skipped":
        body.append("%s<skipped message=%s/></testcase>" % (head, quoteattr(detail[:300])))
    elif kind:
        first = (detail.splitlines()[2:3] or [kind])[0][:300]
        body.append("%s<%s message=%s>%s</%s></testcase>" % (head, kind, quoteattr(first), escape(detail), kind))
    else:
        body.append(head + "</testcase>")
n = lambda k: sum(1 for x in results if x[3] == k)
with open(junit, "w", encoding="utf-8") as f:
    f.write('<?xml version="1.0" encoding="UTF-8"?>\n')
    f.write('<testsuite name="minitest" tests="%d" failures="%d" errors="%d" skipped="%d">\n'
            % (len(results), n("F"), n("E"), n("S")))
    f.write("\n".join(body) + "\n</testsuite>\n")
print("junit: %d cases written to %s" % (len(results), junit))
