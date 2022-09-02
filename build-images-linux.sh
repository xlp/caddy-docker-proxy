#!/bin/bash

set -e

docker buildx create --use
docker run --privileged --rm tonistiigi/binfmt --install all

find artifacts/binaries -type f -exec chmod +x {} \;

#PLATFORMS="linux/amd64,linux/arm/v6,linux/arm/v7,linux/arm64"
PLATFORMS="linux/amd64"
OUTPUT="type=local,dest=local"
TAGS=
TAGS_ALPINE=

#if [[ "${BUILD_SOURCEBRANCH}" == "refs/heads/master" ]]; then
    echo "Building and pushing CI images"


    OUTPUT="type=registry"
    TAGS="-t docker.eternalnet.ch/caddy-docker-proxy:ci"
    TAGS_ALPINE="-t docker.eternalnet.ch/caddy-docker-proxy:ci-alpine"
#fi

if [[ "${BUILD_SOURCEBRANCH}" =~ ^refs/tags/v[0-9]+\.[0-9]+\.[0-9]+(-.*)?$ ]]; then
    RELEASE_VERSION=$(echo $BUILD_SOURCEBRANCH | cut -c11-)

    echo "Releasing version ${RELEASE_VERSION}..."

    PATCH_VERSION=$(echo $RELEASE_VERSION | cut -c2-)
    MINOR_VERSION=$(echo $PATCH_VERSION | cut -d. -f-2)

    OUTPUT="type=registry"
    TAGS="-t docker.eternalnet.ch/caddy-docker-proxy:latest \
        -t docker.eternalnet.ch/caddy-docker-proxy:${PATCH_VERSION} \
        -t docker.eternalnet.ch/caddy-docker-proxy:${MINOR_VERSION}"
    TAGS_ALPINE="-t docker.eternalnet.ch/caddy-docker-proxy:alpine \
        -t docker.eternalnet.ch/caddy-docker-proxy:${PATCH_VERSION}-alpine \
        -t docker.eternalnet.ch/caddy-docker-proxy:${MINOR_VERSION}-alpine"
fi

docker buildx build -f Dockerfile . \
    -o $OUTPUT \
    --platform $PLATFORMS \
    $TAGS

docker buildx build -f Dockerfile-alpine . \
    -o $OUTPUT \
    --platform $PLATFORMS \
    $TAGS_ALPINE
