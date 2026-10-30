# The image AIDEV runs this project's suites in (`environment.image` in
# .aidev/project.yaml). AIDEV runs it as `docker run --rm --network none --user
# <uid>:<gid> -v <workspace>:/work`, so everything a suite needs is in the image.
#
# Based on ruby:3.3, pinned by digest (CI's only job, `pages`, still names
# ruby:2.6.1-alpine, which current dependencies no longer install on). It adds
#   - every gem hive-ruby.gemspec and Gemfile resolve to, installed into the
#     image's system gem path, and the Gemfile.lock that resolution wrote
#     (/opt/hive-ruby/Gemfile.lock; the repository ignores Gemfile.lock), which
#     .aidev/run-checks.sh copies into a checkout that has none.
#
# .aidev/runtime/build.sh builds it; the result is pinned as `environment.image`.
# See .aidev/README.md.
ARG BASE_IMAGE=ruby:3.3@sha256:35460b769ba5f033ccf5525d04acea2612ad471d4ca9c84ace8e9347839d421d
FROM ${BASE_IMAGE}
ENV HOME=/tmp \
    BUNDLE_SILENCE_ROOT_WARNING=1
COPY deps/ /opt/hive-ruby/
RUN cd /opt/hive-ruby \
    && bundle install --jobs 4 \
    && chmod -R a+rX /usr/local/bundle /opt/hive-ruby \
    && rm -rf /tmp/.cache /tmp/.bundle /root/.bundle
