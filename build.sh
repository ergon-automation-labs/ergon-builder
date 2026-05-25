#!/bin/bash
# Build helper script for Bot Army bots
# Usage: ./build.sh <bot-name> [channel] [registry]
# Example: ./build.sh gtd stable ergon-automation-labs

set -euo pipefail

BOT_NAME="${1:?Usage: ./build.sh <bot-name> [channel] [registry]}"
CHANNEL="${2:-stable}"
REGISTRY="${3:-ergon-automation-labs}"
BUILDER_VERSION="${BUILDER_VERSION:-1.0.0}"

IMAGE_TAG="${REGISTRY}/ergon-${BOT_NAME}:${CHANNEL}"

echo "Building Bot Army bot: ${BOT_NAME}"
echo "  Channel: ${CHANNEL}"
echo "  Registry: ${REGISTRY}"
echo "  Builder version: ${BUILDER_VERSION}"
echo "  Image tag: ${IMAGE_TAG}"
echo ""

# Build the image
docker build \
  -f Dockerfile \
  --build-arg BUILDER_VERSION="${BUILDER_VERSION}" \
  --build-arg CHANNEL="${CHANNEL}" \
  -t "${IMAGE_TAG}" \
  -t "${REGISTRY}/ergon-${BOT_NAME}:latest" \
  .

echo ""
echo "✓ Built ${IMAGE_TAG}"
echo ""
echo "Next steps:"
echo "  docker run --rm ${IMAGE_TAG}"
echo "  docker push ${IMAGE_TAG}"
