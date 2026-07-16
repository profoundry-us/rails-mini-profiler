# Common commands for working on Rails Mini Profiler inside Docker.
# Run `just` (or `just --list`) to see everything available.
#
# Requires Docker and `just` (https://github.com/casey/just) on your machine --
# nothing else needs to be installed locally.

# List available recipes
default:
    @just --list

##############################
# Images / containers
##############################

# Build the Docker image
build:
    docker compose build

# Rebuild the image without using the cache
rebuild:
    docker compose build --no-cache

# Open a bash shell in a fresh container
shell:
    docker compose run --rm app bash

# Stop and remove containers
down:
    docker compose down

# Remove containers and volumes (postgres data, etc.)
clean:
    docker compose down --volumes --remove-orphans

##############################
# Tests / linting
##############################

# Run the test suite (default: everything). Uses SQLite unless you set
# DATABASE=postgres. Pass a path/args, e.g.
#   just test spec/lib/rails_mini_profiler/middleware_spec.rb
#   DATABASE=postgres just test
test *args="spec":
    docker compose run --rm -e DATABASE app bash -lc "bundle exec rake db:test:prepare && bundle exec rspec {{args}}"

# Run the default rake task: specs + RuboCop
check:
    docker compose run --rm -e DATABASE app bash -lc "bundle exec rake db:test:prepare && bundle exec rake"

# Run RuboCop
lint:
    docker compose run --rm app bundle exec rubocop

# Run RuboCop with autocorrect
lint-fix:
    docker compose run --rm app bundle exec rubocop -A

# Install JS deps and run the JS + CSS linters
lint-js:
    docker compose run --rm app bash -lc "corepack pnpm install && corepack pnpm run lint && corepack pnpm run lint:css"

# Run an arbitrary rake task, e.g. `just rake db:test:prepare`
rake *args:
    docker compose run --rm app bundle exec rake {{args}}

##############################
# Dummy app
##############################

# Open a Rails console for the dummy app
console:
    docker compose run --rm app bin/rails console

# Start the dummy app at http://localhost:3300 (set RMP_PORT in .env to change the host port)
server:
    docker compose run --rm --service-ports app bin/rails server -b 0.0.0.0

# Build the front-end assets
assets:
    docker compose run --rm app bash -lc "corepack pnpm install && corepack pnpm run build"

##############################
# Database (only needed for DATABASE=postgres)
##############################

# Open a psql shell against the postgres test database
db-shell:
    docker compose up -d db
    docker compose exec db psql -U dummy -d rmp_dummy_test
