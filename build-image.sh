#! /bin/sh
set -e

VERSION=$(cat package.json | jq -r .version)

docker buildx build --platform linux/amd64,linux/arm64 --provenance=true --sbom=true --push -t "yog27ray/action-cache-http-image:$VERSION" -t "yog27ray/action-cache-http-image:latest" ./
