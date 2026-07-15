#!/bin/bash
set -e

# The committed Gemfile.lock only lists the x86_64 (CI) platform. When running
# on Apple Silicon the container is aarch64, so make sure the mounted lockfile
# lists both platforms. This edits the bind-mounted host Gemfile.lock the first
# time you run a container -- commit the change so it works everywhere.
if ! grep -q 'aarch64-linux' Gemfile.lock 2>/dev/null; then
  bundle lock --add-platform x86_64-linux aarch64-linux || true
fi

# Install gems if the image's baked bundle doesn't satisfy the current lockfile
# (e.g. after editing the Gemfile).
bundle check >/dev/null 2>&1 || bundle install

# Run whatever command the container was started with (see docker-compose.yml /
# justfile).
exec "$@"
