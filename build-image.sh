#! /bin/sh
set -e

VERSION=$(cat package.json | jq -r .version)

docker buildx build --provenance=true --sbom=true --load -t "yog27ray/action-cache-http-image:$VERSION" -t "yog27ray/action-cache-http-image:latest" ./
docker push "yog27ray/action-cache-http-image:$VERSION"
docker push "yog27ray/action-cache-http-image:latest"
