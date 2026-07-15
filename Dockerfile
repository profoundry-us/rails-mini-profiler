# Dockerfile for developing and testing the Rails Mini Profiler engine.
#
# This follows the LocoMotion Docker conventions
# (https://loco-motion-demo-staging.profoundry.us/guides/docker) but is adapted
# for a Rails *engine*: the "app" is the dummy application in spec/dummy that the
# test suite boots. Ruby gems are baked into the image; the source tree is
# bind-mounted at runtime (see docker-compose.yml) so code changes are picked up
# without rebuilding.

FROM ruby:3.4.3

# System dependencies:
#   build-essential  - compile native gem extensions (stackprof, etc.)
#   git              - some tooling shells out to git
#   tini             - proper PID 1 / signal handling
#   postgresql-client, libpq-dev - the `pg` gem (used when DATABASE=postgres)
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    tini \
    postgresql-client \
    libpq-dev \
  && rm -rf /var/lib/apt/lists/*

# Node.js 22.x + pnpm (via corepack) for linting and building front-end assets.
# Tests do not need Node, but `just lint-js` / `just assets` do.
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
  && apt-get install -y --no-install-recommends nodejs \
  && corepack enable \
  && rm -rf /var/lib/apt/lists/*

ENV APP_HOME=/home/app
WORKDIR $APP_HOME

# Install gems in their own layer. We only copy the files Bundler needs to
# resolve the gemspec so this layer is cached until the dependencies change.
# The lockfile only ships the x86_64 (CI) platform, so add aarch64 (Apple
# Silicon) before installing.
COPY Gemfile Gemfile.lock rails_mini_profiler.gemspec ./
COPY lib/rails_mini_profiler/version.rb lib/rails_mini_profiler/version.rb
RUN bundle lock --add-platform x86_64-linux aarch64-linux \
  && bundle install

COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["/usr/bin/tini", "--", "entrypoint.sh"]

EXPOSE 3000

CMD ["bash"]
