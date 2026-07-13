# Bot Army Builder Image (v1.0.0)
# Provides Erlang 26 + build tools for Elixir bot compilation
# Usage: FROM ergon-automation-labs/ergon-builder:1.0.0 as builder

FROM erlang:27-alpine

LABEL maintainer="ergon-automation-labs"
LABEL description="Bot Army builder image (Erlang 26 + build tools)"

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    git \
    bash \
    ca-certificates \
    curl \
    openssl \
    && rm -rf /var/cache/apk/*

# Install Elixir
RUN apk add --no-cache elixir

# Create app directory
WORKDIR /app

# Default: no command (bot repos override)
CMD ["/bin/sh"]
