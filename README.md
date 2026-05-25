# Bot Army Builder

Shared base image and build templates for Bot Army bots. Ensures consistent Docker images across all 23+ bots in the ecosystem.

**Base Image:** `erlang:26-alpine` + common dependencies (bash, curl, ca-certificates, openssl, dumb-init)

**Version:** 1.0.0

---

## Quick Start

Each bot repo uses this builder to create its Docker image.

### 1. Copy Template to Your Bot Repo

```bash
cd ergon-automation-labs/ergon-gtd
curl -o Dockerfile https://raw.githubusercontent.com/ergon-automation-labs/bot-army-builder/main/Dockerfile.template
# Edit Dockerfile: replace <BOT_NAME> with your bot name (gtd_bot)
```

### 2. Build Image

```bash
# Via helper script
./scripts/build.sh gtd stable ergon-automation-labs

# Or directly with docker
docker build -f Dockerfile -t ergon-automation-labs/ergon-gtd:stable .
```

### 3. Verify

```bash
docker run --rm ergon-automation-labs/ergon-gtd:stable gtd_bot eval "IO.inspect(System.version())"
```

---

## Image Naming Convention

```
ergon-automation-labs/ergon-<bot-name>:<channel>
```

**Channels:**
- `stable` — Frozen release (manual tag when confident in code)
- `latest` — Recent stable build (auto-tagged on release)
- `nightly` — Main branch (cutting edge, auto-tagged on push)
- `v0.7.1` — Version tags for specific releases

**Examples:**
- `ergon-automation-labs/ergon-gtd:stable`
- `ergon-automation-labs/ergon-llm:nightly`
- `ergon-automation-labs/ergon-dispatcher:v0.5.5`

---

## Dockerfile Structure

### Minimal Example (gtd_bot)

```dockerfile
FROM ergon-automation-labs/bot-army-builder:1.0.0 as builder

WORKDIR /app
RUN apk add --no-cache build-base git elixir
COPY mix.exs mix.lock ./
RUN mix local.hex --force && mix local.rebar --force && mix deps.get --only prod

COPY . .
RUN mix compile --prod && mix release

# Runtime
FROM ergon-automation-labs/bot-army-builder:base

COPY --from=builder /app/_build/prod/rel/gtd_bot /app/bin/

ENV MIX_ENV=prod
ENV NATS_SERVERS=nats://nats:4222
ENV DATABASE_URL=postgres://postgres:postgres@postgres:5432/bot_army_prod

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8888/health || exit 1

CMD ["gtd_bot", "start"]
```

### With Custom Build Steps

If your bot has special dependencies or build needs:

```dockerfile
FROM ergon-automation-labs/bot-army-builder:1.0.0 as builder

WORKDIR /app

# Custom build steps
RUN apk add --no-cache build-base git elixir postgresql-client
# ... rest of build

FROM ergon-automation-labs/bot-army-builder:base

# Your release
COPY --from=builder /app/_build/prod/rel/your_bot /app/bin/

# Optional: install runtime-only deps
RUN apk add --no-cache postgresql-client

CMD ["your_bot", "start"]
```

---

## Environment Variables

All bots should support these at runtime (override in docker-compose or helm):

| Variable | Default | Purpose |
|----------|---------|---------|
| `MIX_ENV` | `prod` | Elixir environment |
| `NATS_SERVERS` | `nats://nats:4222` | NATS broker endpoints (comma-separated for HA) |
| `DATABASE_URL` | `postgres://...` | PostgreSQL connection string |

**Example Override:**

```bash
docker run \
  -e NATS_SERVERS=nats://nats:4222,nats://nats:14223 \
  -e DATABASE_URL=postgres://prod-user:pass@prod-db:5432/bot_army \
  ergon-automation-labs/ergon-gtd:stable
```

---

## Health Checks

All bots must implement a health check endpoint at `GET http://localhost:8888/health`.

Return:
- **200 OK** — Bot is healthy
- **503 Service Unavailable** — Bot is starting/degraded
- **Non-200** — Bot is unhealthy

Example in Elixir (using Plug):

```elixir
defmodule MyBot.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  match "/health" do
    send_resp(conn, 200, "OK")
  end
end
```

Docker will automatically restart bots that fail health checks.

---

## CI/CD Integration

### GitHub Actions (in bot repos)

```yaml
name: Build and Push Bot Image

on:
  push:
    branches: [main, stable]
    tags: [v*]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Determine channel
        id: channel
        run: |
          if [[ $GITHUB_REF == refs/tags/* ]]; then
            echo "channel=stable" >> $GITHUB_OUTPUT
          elif [[ $GITHUB_REF == refs/heads/stable ]]; then
            echo "channel=latest" >> $GITHUB_OUTPUT
          else
            echo "channel=nightly" >> $GITHUB_OUTPUT
          fi
      
      - name: Build and push
        uses: docker/build-push-action@v4
        with:
          push: true
          tags: |
            ergon-automation-labs/ergon-${{ github.event.repository.name }}:${{ steps.channel.outputs.channel }}
            ergon-automation-labs/ergon-${{ github.event.repository.name }}:latest
```

---

## Versioning

### Base Image Versions

When updating the base image (new Erlang version, new dependencies), increment `BUILDER_VERSION`:

- `1.0.0` — Initial (Erlang 26 + bash, curl, ca-certificates, openssl, dumb-init)
- `1.1.0` — New dependency added, Erlang 26 base unchanged
- `2.0.0` — Major change (e.g., Erlang 27)

Update bot Dockerfiles to use new version:

```dockerfile
FROM ergon-automation-labs/bot-army-builder:1.1.0 as builder
```

---

## Building Locally

```bash
# Build base image locally (for testing)
docker build -f Dockerfile.base -t bot-army-builder:1.0.0 .

# Test with a bot
cd ../ergon-gtd
docker build \
  --build-arg BUILDER_VERSION=1.0.0 \
  -t ergon-gtd:test \
  .

docker run --rm ergon-gtd:test gtd_bot eval "IO.inspect(:erlang.system_info(:version))"
```

---

## References

- **Bot Army Starter:** Pulls built bot images, creates pack images
- **Individual Bot Repos:** Use this builder to create images
- **Docker Compose:** References pack images built by Starter

---

## License

Apache 2.0 — Same as Bot Army
