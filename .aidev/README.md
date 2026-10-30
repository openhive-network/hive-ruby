# Automated contributions

This directory configures the automated development platform that contributes to this
repository. This note says which branches it uses here and how its work reaches the
project's main line.

## Branches

- `aidev/integration` — the integration branch. Automated work lands here and nowhere else.
- `master` — the project's main line; reached from `aidev/integration` only by merge request
  (`aidev handoff`). Merge integration MRs **keeping the source branch**
  (`aidev/integration` is protected, so GitLab never deletes it).
- `ai/*` — one branch per task, created and deleted by the platform. Do not commit to them.
- `session/*` — a session's accumulated work, landed on the integration branch as a batch.

## How work reaches the main line

Task and session branches never reach `aidev/integration` through merge requests; the platform
lands them after its own verification. `aidev/integration` reaches `master` by this project's
usual process, merge requests included — the platform never merges into any other branch.

Whether this project's CI pipelines skip `ai/*` and `session/*` branches is decided by the
project's CI rules (today `.gitlab-ci.yml` has one job, `pages`, limited to `master`, so `ai/*`, `session/*` and `aidev/integration` pushes start no pipeline).

## Suites run before work lands

Declared in `.aidev/project.yaml` under `verification`, all through `.aidev/run-checks.sh`,
which writes `test-results/<slot>/junit.xml` (one case per step, plus minitest's per-test junit as `unit-junit.xml`):

- `quick`, `full`, `canary`, `system` — `unit syntax docs`
- `baseline`, `coverage` — `unit`
- `static` — `syntax docs`

Steps: `unit` is the Rakefile's default `test` task (every `test/**/*_test.rb`, `-W1`, libs `lib` and `test`), loaded directly with minitest `-v` so the run writes per-test junit, and excluding by name every test listed in `.aidev/network-tests.txt`; `syntax` is `ruby -wc` over every `.rb` file in `lib/` and `test/` and the `Rakefile` (warnings are printed, only syntax errors fail); `docs` is `bundle exec yard`, what CI's only job (`pages`) runs. The unit suite keeps 52 tests offline (25 of them skip themselves: disabled APIs, the OpenSSL 3 signing quarantine, cassettes marked unusable). The whole set takes a few seconds.

`coverage` runs the unit suite, which measures through SimpleCov (`test/test_helper.rb`; report in `coverage/`, ignored by git). `system` has no real services to run against and repeats the full set. There is no linter (no RuboCop configuration).

### Not run (network)

- 251 tests, listed by name with the reason in `.aidev/network-tests.txt`: they call `api.openhive.network`, and their VCR cassettes are not in the repository (`.gitignore` lists `test/fixtures/vcr_cassettes/*.yml`), so VCR records instead of replaying. Committing cassettes would let them run offline; a test taken off the list must pass with no network.
- `rake test:testnet`, `test:threads` and the `stream:*` tasks need a live node.

`test-results/` is not in `.gitignore`; do not commit it.

## Test runtime

`.aidev/runtime/Dockerfile` builds on `ruby:3.3`, pinned by digest, and installs every gem `hive-ruby.gemspec` resolves to (CI's `pages` job still names `ruby:2.6.1-alpine`, which the current dependencies do not install on). The repository ignores `Gemfile.lock`; the image keeps the lock its `bundle install` wrote at `/opt/hive-ruby/Gemfile.lock`, and `.aidev/run-checks.sh` copies it into a checkout that has none, so every run uses the gems the image holds. Rebuild and re-pin with `.aidev/runtime/build.sh --push` when `Gemfile` or `hive-ruby.gemspec` changes (`environment.inputs`), and put the printed `repo@sha256:…` into `environment.image`.
